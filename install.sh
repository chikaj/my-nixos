#!/usr/bin/env bash

set -euo pipefail

# Disko and partitioning step:
echo "Enter your target device (e.g., /dev/nvme2n1):"
read DEVICENAME
DEVICENAME=$(echo "$DEVICENAME" | tr -d '\n')
if [ -z "$DEVICENAME" ]; then
    echo "Error: DEVICENAME is not set." >&2
    exit 1
fi

# Copy and modify template disko-config, replacing device name
sed "s|/dev/mydisk|$DEVICENAME|g" ./disko-config-template.nix > ./disko-config.nix

# Trigger disko with supplied config and password
# ##### THE PASSWORD ENTERED PREVIOUSLY ISN'T USED IN THE FOLLOWING COMMAND. CAN IT BE USE? OTHERWISE, WHY ASK FOR IT?
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount ./disko-config.nix

echo "Disk partitioning complete. Proceeding with NixOS install steps."

# === MOUNT PARTITIONS ===
# Detect LUKS partition dynamically
CRYPTROOT=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$3=="crypto_LUKS"{print "/dev/" $1}' | head -n1)
if [ -z "$CRYPTROOT" ]; then
    echo "Error: No LUKS partition found." >&2
    exit 1
fi

# Detect EFI partition dynamically (vfat + bootable)
EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$2=="part" && $3=="vfat" {print "/dev/" $1}' | head -n1)
if [ -z "$EFI" ]; then
    # Fallback: first vfat if boot flag not set
    EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln -p | awk '$3=="vfat"{print "/dev/" $1}' | head -n1)
fi
if [ -z "$EFI" ]; then
    echo "Error: No EFI partition found." >&2
    exit 1
fi

# Unlock LUKS root if needed
if ! mount | grep -q "/mnt "; then
    sudo cryptsetup open "$CRYPTROOT" cryptroot
fi

# # Mount root subvolume only
# for subvol in root; do
#     target="/mnt"
#     sudo mount -o subvol="$subvol",compress=zstd,noatime /dev/mapper/cryptroot "$target"
# done

# Create mount points
sudo mkdir -p /mnt/{etc,nix,home,persist,boot}
sudo mkdir -p /mnt/{etc/nixos,var/log}

# Mount Btrfs subvolumes
for subvol in root nix home persist log; do
    target="/mnt"
    [ "$subvol" = "log" ] && target="/mnt/var/log"
    [ "$subvol" != "root" ] && [ "$subvol" != "log" ] && target="/mnt/$subvol"
    sudo mount -o subvol="$subvol",compress=zstd,noatime /dev/mapper/cryptroot "$target"
done

# Mount EFI partition
sudo mount -t vfat "$EFI" /mnt/boot
# === END MOUNT ===

# Get EFI partition UUID for stable filesystem reference
BOOTUUID=$(sudo blkid -s UUID -o value "$EFI" 2>/dev/null || echo "")
if [ -z "$BOOTUUID" ]; then
    echo "Error: Could not determine EFI partition UUID." >&2
    exit 1
fi
echo "DEBUG: BOOTUUID='$BOOTUUID'"

# Query user information
read -p "Enter desired hostname: " HOSTNAME
HOSTNAME=$(echo "$HOSTNAME" | tr -d '\n')
echo "DEBUG: After read HOSTNAME='$HOSTNAME'"
if [ -z "$HOSTNAME" ]; then
    echo "Error: HOSTNAME is not set." >&2
    exit 1
fi
# timedatectl list-timezones
read -p "Enter desired time zone (e.g., America/Chicago): " TIMEZONE
TIMEZONE=$(echo "$TIMEZONE" | tr -d '\n')
echo "DEBUG: After read TIMEZONE='$TIMEZONE'"
if [ -z "$TIMEZONE" ]; then
    echo "Error: TIMEZONE is not set." >&2
    exit 1
fi

read -p "Enter desired username: " USERNAME
USERNAME=$(echo "$USERNAME" | tr -d '\n')
echo "DEBUG: After read USERNAME='$USERNAME'"
echo "DEBUG: About to prompt for password"
if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME is not set." >&2
    exit 1
fi

read -s -p "Enter password: " PASSWORD
echo
read -s -p "Confirm password: " PASSWORD2
echo
if [ "$PASSWORD" != "$PASSWORD2" ]; then
  echo "User passwords do not match!" >&2
  exit 1
fi

read -p "Does this machine have an NVIDIA GPU? (y/N): " HAS_NVIDIA
HAS_NVIDIA=$(echo "$HAS_NVIDIA" | tr -d '\n')

echo "DEBUG: Before nixos-generate-config, PASSWORD set"
echo "DEBUG: Running nixos-generate-config --root /mnt"

# Generate hardware config (skip filesystems to avoid duplicates with our template)
sudo nixos-generate-config --root /mnt --no-filesystems

echo "DEBUG: After nixos-generate-config, checking /mnt/etc/nixos:"
sudo ls -la /mnt/etc/nixos/ 2>&1 || echo "Directory does not exist"

# Copy modules and home directories to /mnt/etc/nixos
# Substitute variables in the files
sudo cp -r ./nixos/modules /mnt/etc/nixos/
sudo cp -r ./nixos/home /mnt/etc/nixos/

# Remove NVIDIA module on non-NVIDIA machines
if [ "$HAS_NVIDIA" != "y" ] && [ "$HAS_NVIDIA" != "Y" ]; then
    echo "NVIDIA GPU not detected — removing NVIDIA module."
    sudo rm /mnt/etc/nixos/modules/02-nvidia.nix
fi

# Substitute variables in the copied directories
sudo find /mnt/etc/nixos/modules /mnt/etc/nixos/home -type f -name "*.nix" -exec sed -i \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    {} \;

CONFIG_TEMPLATE=./nixos/configuration-template.nix
FLAKE_TEMPLATE=./nixos/flake-template.nix
HOME_TEMPLATE=./nixos/home-template.nix

echo "DEBUG: Current directory: $(pwd)"
echo "DEBUG: Checking template files exist:"
ls -la "$CONFIG_TEMPLATE" "$FLAKE_TEMPLATE" "$HOME_TEMPLATE" 2>&1 || echo "Templates do not exist"

echo "DEBUG: Variable values:"
echo "  HOSTNAME='$HOSTNAME'"
echo "  TIMEZONE='$TIMEZONE'"
echo "  USERNAME='$USERNAME'"
echo "  PASSWORD='$PASSWORD'"
echo "  HAS_NVIDIA='$HAS_NVIDIA'"

CONFIG_OUTPUT=./configuration.nix
FLAKE_OUTPUT=./flake.nix
HOME_OUTPUT=./home.nix

# Substitute variables into config template
echo "DEBUG: Before sed - showing variable values:"
echo "  HOSTNAME='$HOSTNAME'"
echo "  TIMEZONE='$TIMEZONE'"
echo "  USERNAME='$USERNAME'"
echo "  PASSWORD='$PASSWORD'"
echo "DEBUG: Running sed on configuration-template.nix"
sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    -e "s|BOOTUUID|$BOOTUUID|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

echo "DEBUG: Running sed on flake-template.nix"
sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    "$FLAKE_TEMPLATE" > "$FLAKE_OUTPUT"

echo "DEBUG: Running sed on home-template.nix"
sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    "$HOME_TEMPLATE" > "$HOME_OUTPUT"

# Write generated configs to debug files for inspection
if [ -f ./configuration.nix ]; then
    cat ./configuration.nix > ./debug-config.txt
    echo "DEBUG: configuration.nix written to ./debug-config.txt"
else
    echo "DEBUG: ERROR - ./configuration.nix does not exist"
fi

# Write flake to file for inspection
if [ -f ./flake.nix ]; then
    cat ./flake.nix > ./debug-flake.txt
    echo "DEBUG: flake.nix written to ./debug-flake.txt"
else
    echo "DEBUG: ERROR - ./flake.nix does not exist"
fi

echo "DEBUG: Checking files exist in /mnt/etc/nixos:"
sudo ls -la /mnt/etc/nixos/ 2>&1 || echo "Directory does not exist"

sudo cp "$CONFIG_OUTPUT" /mnt/etc/nixos/configuration.nix
sudo cp "$FLAKE_OUTPUT" /mnt/etc/nixos/flake.nix
sudo cp "$HOME_OUTPUT" /mnt/etc/nixos/home.nix

echo "All configs are now in /mnt/etc/nixos/."
echo "Confirm partitions with: lsblk."
echo "Verify that /mnt/etc/nixos/hardware-configuration.nix exists."
echo "Verify that configuration.nix and flake.nix are templated correctly"
echo "Running the following should not return anything."
echo "  grep HOSTNAME /mnt/etc/nixos/flake.nix"
echo "  grep USERNAME /mnt/etc/nixos/modules/01-user.nix"
echo "  grep PASSWORD /mnt/etc/nixos/modules/01-user.nix"
echo "  grep TIMEZONE /mnt/etc/nixos/modules/00-default.nix"
echo "Confirm mount points with: mount | grep /mnt"

# Generate lock file and install with flakes
sudo env NIX_CONFIG="extra-experimental-features = nix-command flakes" \
  nix flake lock /mnt/etc/nixos
sudo env NIX_CONFIG="extra-experimental-features = nix-command flakes" \
  nixos-install --flake /mnt/etc/nixos#${HOSTNAME}
