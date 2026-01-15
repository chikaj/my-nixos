#!/usr/bin/env bash

# Disk module - handles disko partitioning and mounting operations
# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Prompt for disk information
prompt_disk_info() {
    log_info "=== Disk Configuration ==="

    echo "Available devices:"
    lsblk -d -o NAME,SIZE,MODEL

    echo
    read -p "Enter your target device (e.g., /dev/nvme2n1): " DEVICENAME

    if ! validate_device "$DEVICENAME"; then
        exit 1
    fi

    echo
    prompt_password "Enter your desired LUKS password: " LUKSPASS LUKSPASS2
}

# Create disko configuration from template
create_disko_config() {
    local template_path="${SCRIPT_DIR}/../templates/disko-config.nix"
    local output_path="./disko-config.nix"

    log_info "Creating disko configuration..."

    # Check if template exists
    if [ ! -f "$template_path" ]; then
        log_error "Disko template not found at $template_path"
        exit 1
    fi

    # Replace device name in template
    sed "s|/dev/mydisk|$DEVICENAME|g" "$template_path" > "$output_path"

    log_success "Disko configuration created: $output_path"
}

# Run disko partitioning
run_disko() {
    log_info "Running disko partitioning..."

    # Write password to temporary keyfile
    echo -n "$LUKSPASS" > /tmp/secret.key
    chmod 600 /tmp/secret.key

    # Run disko with config
    sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko ./disko-config.nix

    # Remove temporary keyfile for security
    rm -f /tmp/secret.key

    log_success "Disk partitioning complete"
}

# Mount filesystems after partitioning
mount_filesystems() {
    log_info "Mounting filesystems..."

    # Detect LUKS partition dynamically
    CRYPTROOT=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$3=="crypto_LUKS"{print "/dev/" $1}' | head -n1)
    if [ -z "$CRYPTROOT" ]; then
        log_error "No LUKS partition found"
        exit 1
    fi

    # Detect EFI partition dynamically
    EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$2=="part" && $3=="vfat" {print "/dev/" $1}' | head -n1)
    if [ -z "$EFI" ]; then
        # Fallback: first vfat if boot flag not set
        EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln -p | awk '$3=="vfat"{print "/dev/" $1}' | head -n1)
    fi
    if [ -z "$EFI" ]; then
        log_error "No EFI partition found"
        exit 1
    fi

    # Unlock LUKS root if needed
    if ! mount | grep -q "/mnt "; then
        sudo cryptsetup open "$CRYPTROOT" cryptroot
    fi

    # Create mount points
    sudo mkdir -p /mnt/{etc,nix,home,persist,boot}
    sudo mkdir -p /mnt/etc/nixos

    # Mount Btrfs subvolumes
    for subvol in root nix home persist; do
        target="/mnt"
        [ "$subvol" != "root" ] && target="/mnt/$subvol"
        sudo mount -o subvol="$subvol",compress=zstd,noatime /dev/mapper/cryptroot "$target"
    done

    # Mount EFI partition
    sudo mount -t vfat "$EFI" /mnt/boot

    log_success "Filesystems mounted successfully"
}

# Verify mount points
verify_mounts() {
    log_info "Verifying mount points..."
    mount | grep /mnt
    log_success "Mount verification complete"
}

# Save disk state for later modules
save_disk_state() {
    log_info "Saving disk state..."

    # Detect partitions
    CRYPTROOT=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$3=="crypto_LUKS"{print "/dev/" $1}' | head -n1)
    EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$2=="part" && $3=="vfat" {print "/dev/" $1}' | head -n1)

    # Create state file (without passwords for security)
    cat > /tmp/disk-state.json << EOF
{
  "device": "$DEVICENAME",
  "luks_device": "/dev/mapper/cryptroot",
  "luks_partition": "$CRYPTROOT",
  "efi_partition": "$EFI",
  "mount_points": {
    "root": "/mnt",
    "boot": "/mnt/boot",
    "nix": "/mnt/nix",
    "home": "/mnt/home",
    "persist": "/mnt/persist"
  },
  "disks_ready": true
}
EOF

    log_success "Disk state saved to /tmp/disk-state.json"
}

# Main disk setup function
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

# Mount filesystems only (for recovery/debugging)
mount_only() {
    log_info "Mounting existing filesystems..."

    echo "Available devices:"
    lsblk -d -o NAME,SIZE,MODEL

    echo
    read -p "Enter your target device (e.g., /dev/nvme2n1): " DEVICENAME

    if ! validate_device "$DEVICENAME"; then
        exit 1
    fi

    mount_filesystems
    verify_mounts
    save_disk_state
}

# Show help
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

# Main execution
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
