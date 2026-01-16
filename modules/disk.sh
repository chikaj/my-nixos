#!/usr/bin/env bash
# Disk module - handles disko partitioning and mounting operations

set -euo pipefail

# Source common utilities (log_* functions, validators, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Target mountpoint (override by exporting TARGET_MNT=/some/where if desired)
TARGET_MNT="${TARGET_MNT:-/mnt}"

# ------------------------------
# Helpers
# ------------------------------

find_luks_under_device() {
  # Return the first crypto_LUKS partition under $DEVICENAME
  lsblk -ln -o NAME,TYPE,FSTYPE "$DEVICENAME" \
    | awk '$2=="part" && $3=="crypto_LUKS"{print "/dev/"$1; exit}'
}

find_esp_under_device() {
  # Prefer a vfat partition with the UEFI ESP GUID under $DEVICENAME.
  # Fallback to the first vfat partition on the system if needed.
  local esp
  esp=$(lsblk -ln -o NAME,TYPE,FSTYPE,PARTTYPE "$DEVICENAME" \
        | awk 'tolower($2)=="part" && (tolower($3)=="vfat" || tolower($4)=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"){print "/dev/"$1; exit}')
  if [ -n "${esp:-}" ]; then
    echo "$esp"
    return 0
  fi
  lsblk -ln -o NAME,FSTYPE \
    | awk 'tolower($2)=="vfat"{print "/dev/"$1; exit}'
}

list_btrfs_subvol_paths() {
  # List subvolume paths (relative to filesystem root) for the device mounted at $1
  local mp="$1"
  sudo btrfs subvolume list "$mp" | awk '{print $9}'
}

subvol_exists() {
  # Check if a subvolume path exists (relative to FS root) on a btrfs mountpoint
  local mp="$1"
  local path="$2"   # e.g., root, /root, nix, /nix
  local needle="${path#/}" # strip leading /
  list_btrfs_subvol_paths "$mp" | grep -qx -- "$needle"
}

# ------------------------------
# Interactive prompts
# ------------------------------

prompt_disk_info() {
  log_info "=== Disk Configuration ==="

  echo "Available devices:"
  lsblk -d -o NAME,SIZE,MODEL

  echo
  read -p "Enter your target device (e.g., /dev/nvme0n1): " DEVICENAME

  if ! validate_device "$DEVICENAME"; then
    exit 1
  fi

  echo
  prompt_password "Enter your desired LUKS password: " LUKSPASS LUKSPASS2
}

# ------------------------------
# Disko config creation & run
# ------------------------------

create_disko_config() {
  local template_path="${SCRIPT_DIR}/../templates/disko-config.nix"
  local output_path="./disko-config.nix"

  log_info "Creating disko configuration..."

  if [ ! -f "$template_path" ]; then
    log_error "Disko template not found at $template_path"
    exit 1
  fi

  # Replace the placeholder device in the template
  sed -e "s|/dev/mydisk|$DEVICENAME|g" "$template_path" > "$output_path"

  log_success "Disko configuration created: $output_path"
}

run_disko() {
  log_info "Running disko partitioning..."

  # Write password to temporary keyfile (if your template references it)
  echo -n "$LUKSPASS" > /tmp/secret.key
  chmod 600 /tmp/secret.key

  # Run disko
  sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko ./disko-config.nix

  # Remove temporary keyfile for security
  rm -f /tmp/secret.key

  log_success "Disk partitioning complete"
}

# ------------------------------
# Mounting logic (hardened)
# ------------------------------

mount_filesystems() {
  log_info "Mounting filesystems..."

  # Detect LUKS and ESP partitions
  CRYPTROOT="$(find_luks_under_device || true)"
  if [ -z "${CRYPTROOT:-}" ]; then
    log_error "No LUKS (crypto_LUKS) partition found under $DEVICENAME"
    exit 1
  fi

  EFI="$(find_esp_under_device || true)"
  if [ -z "${EFI:-}" ]; then
    log_error "No EFI (vfat) partition found"
    exit 1
  fi

  # Open LUKS if needed
  if [ ! -e /dev/mapper/cryptroot ]; then
    log_info "Opening LUKS container..."
    sudo cryptsetup open "$CRYPTROOT" cryptroot
  fi

  # Ensure target mountpoint exists
  sudo mkdir -p "$TARGET_MNT"

  # Mount the intended root subvolume, no unsafe fallback
  log_info "Mounting Btrfs root subvolume at $TARGET_MNT"
  if sudo mount -o subvol=root,compress=zstd,noatime /dev/mapper/cryptroot "$TARGET_MNT"; then
    :
  elif sudo mount -o subvol=/root,compress=zstd,noatime /dev/mapper/cryptroot "$TARGET_MNT"; then
    :
  else
    log_error "Could not mount subvol 'root' (or '/root') on $TARGET_MNT"
    log_error "Listing available subvolumes for diagnostics:"
    local tmpmnt
    tmpmnt="$(mktemp -d)"
    if sudo mount /dev/mapper/cryptroot "$tmpmnt"; then
      list_btrfs_subvol_paths "$tmpmnt" | sed 's/^/  - /'
      sudo umount "$tmpmnt"
    fi
    rmdir "$tmpmnt" 2>/dev/null || true
    exit 1
  fi

  # Verify /mnt is Btrfs and confirm subvol
  if [ "$(findmnt -no FSTYPE "$TARGET_MNT" 2>/dev/null)" != "btrfs" ]; then
    log_error "$TARGET_MNT is not a Btrfs mount; aborting."
    exit 1
  fi
  if ! sudo btrfs subvolume show "$TARGET_MNT" | grep -qE '^Name:\s+root$'; then
    log_warning "Mounted subvolume at $TARGET_MNT is not named 'root' (this may be OK if your layout uses a different name/path)."
  fi

  # Create mount points *after* root is mounted (avoid shadowing)
  sudo mkdir -p "$TARGET_MNT/boot"

  # Determine which optional subvolumes exist before mounting them
  # We try to mount: nix, home, persist, log (if present)
  declare -a WANT_SUBVOLS=("nix" "home" "persist" "log")
  for subvol in "${WANT_SUBVOLS[@]}"; do
    if subvol_exists "$TARGET_MNT" "$subvol"; then
      local target="$TARGET_MNT/$subvol"
      [ "$subvol" = "log" ] && target="$TARGET_MNT/var/log"
      log_info "Mounting subvolume '$subvol' at '$target'"
      sudo mkdir -p "$target"
      sudo mount -o "subvol=$subvol,compress=zstd,noatime" /dev/mapper/cryptroot "$target"
    else
      log_info "Subvolume '$subvol' not found; skipping."
    fi
  done

  # Mount ESP with sane permissions
  log_info "Mounting ESP $EFI at $TARGET_MNT/boot"
  sudo mount -t vfat -o umask=0077 "$EFI" "$TARGET_MNT/boot"

  # Final sanity
  log_info "Verifying Btrfs subvolumes at $TARGET_MNT"
  sudo btrfs subvolume list "$TARGET_MNT" >/dev/null 2>&1 \
    || { log_error "Btrfs subvolumes are not accessible at $TARGET_MNT"; exit 1; }

  log_success "Filesystems mounted successfully"
}

verify_mounts() {
  log_info "Verifying mount points..."
  mount | grep " $TARGET_MNT " || true
  echo
  echo "Source /dev/mapper/cryptroot view:"
  findmnt -r -S /dev/mapper/cryptroot | sed 's/^/  /' || true
  log_success "Mount verification complete"
}

save_disk_state() {
  log_info "Saving disk state..."

  CRYPTROOT="$(find_luks_under_device || true)"
  EFI="$(find_esp_under_device || true)"

  cat > /tmp/disk-state.json << EOF
{
  "device": "$DEVICENAME",
  "luks_device": "/dev/mapper/cryptroot",
  "luks_partition": "${CRYPTROOT:-unknown}",
  "efi_partition": "${EFI:-unknown}",
  "mount_points": {
    "root": "$TARGET_MNT",
    "boot": "$TARGET_MNT/boot",
    "nix": "$TARGET_MNT/nix",
    "home": "$TARGET_MNT/home",
    "persist": "$TARGET_MNT/persist",
    "log": "$TARGET_MNT/var/log"
  },
  "disks_ready": true
}
EOF

  log_success "Disk state saved to /tmp/disk-state.json"
}

# ------------------------------
# Entrypoints
# ------------------------------

setup_disk() {
  log_info "Starting disk setup..."

  prompt_disk_info
  create_disko_config
  run_disko
  mount_filesystems
  verify_mounts
  save_disk_state

  log_success "Disk setup complete. Proceeding with NixOS installation."
}

mount_only() {
  log_info "Mounting existing filesystems..."

  echo "Available devices:"
  lsblk -d -o NAME,SIZE,MODEL

  echo
  read -p "Enter your target device (e.g., /dev/nvme0n1): " DEVICENAME

  if ! validate_device "$DEVICENAME"; then
    exit 1
  fi

  mount_filesystems
  verify_mounts
  save_disk_state
}

show_help() {
  echo "Disk module - Handle disk partitioning and mounting"
  echo
  echo "Usage: $0 [command]"
  echo
  echo "Commands:"
  echo "  setup    - Full disk setup (partition and mount)"
  echo "  mount    - Mount existing filesystems only"
  echo "  help     - Show this help"
  echo
}

case "${1:-setup}" in
  setup)
    setup_disk
    ;;
  mount)
    mount_only
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    log_error "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
