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
# Get LUKS partition UUID for the cryptroot device
CRYPTUUID=$(sudo blkid -s UUID -o value "$CRYPTROOT" 2>/dev/null || echo "")
if [ -z "$CRYPTUUID" ]; then
    echo "Error: Could not determine LUKS partition UUID." >&2
    exit 1
fi

# Query user information
read -p "Enter desired hostname: " HOSTNAME
HOSTNAME=$(echo "$HOSTNAME" | tr -d '\n')
if [ -z "$HOSTNAME" ]; then
    echo "Error: HOSTNAME is not set." >&2
    exit 1
fi
# timedatectl list-timezones
read -p "Enter desired time zone (e.g., America/Chicago): " TIMEZONE
TIMEZONE=$(echo "$TIMEZONE" | tr -d '\n')
if [ -z "$TIMEZONE" ]; then
    echo "Error: TIMEZONE is not set." >&2
    exit 1
fi

read -p "Enter desired username: " USERNAME
USERNAME=$(echo "$USERNAME" | tr -d '\n')
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

# Generate hardware config (skip filesystems to avoid duplicates with our template)
sudo nixos-generate-config --root /mnt --no-filesystems

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

CONFIG_OUTPUT=./configuration.nix
FLAKE_OUTPUT=./flake.nix
HOME_OUTPUT=./home.nix

# Substitute variables into config template
sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    -e "s|BOOTUUID|$BOOTUUID|g" \
    -e "s|CRYPTUUID|$CRYPTUUID|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    "$FLAKE_TEMPLATE" > "$FLAKE_OUTPUT"

sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    "$HOME_TEMPLATE" > "$HOME_OUTPUT"

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
