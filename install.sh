#!/usr/bin/env bash

set -euo pipefail

# Disko and partitioning step:
echo "Enter your target device (e.g., /dev/nvme2n1):"
read DEVICENAME

echo 
read -s -p "Enter your desired LUKS password: " LUKSPASS

echo
read -s -p "Confirm desired LUKS password: " LUKSPASS2
echo
if [ "$LUKSPASS" != "$LUKSPASS2" ]; then
  echo "Passwords do not match!" >&2
  exit 1
fi

# Write password to a temporary keyfile
echo -n "$LUKSPASS" > /tmp/secret.key

# Copy and modify template disko-config, replacing device name
sed "s|/dev/mydisk|$DEVICENAME|g" ./disko/disko-config-template.nix > ./disko-config.nix

# Trigger disko with supplied config and password
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko ./disko-config.nix

# Remove temporary keyfile after partitioning for security
rm -f /tmp/secret.key

echo "Disk partitioning complete. Proceeding with NixOS install steps."

# === MOUNT PARTITIONS ===
# Detect LUKS partition dynamically
CRYPTROOT=$(lsblk -o NAME,TYPE,FSTYPE -ln -p | awk '$3=="crypto_LUKS"{print "/dev/" $1}' | head -n1)
if [ -z "$CRYPTROOT" ]; then
    echo "Error: No LUKS partition found." >&2
    exit 1
fi

# Detect EFI partition dynamically (vfat + bootable)
EFI=$(lsblk -o NAME,TYPE,FSTYPE,PARTFLAGS -ln -p | awk '$3=="vfat" && $4 ~ /boot/ {print "/dev/" $1}' | head -n1)
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

# Create mount points
sudo mkdir -p /mnt/{nix,home,persist,boot}

# Mount Btrfs subvolumes
for subvol in root nix home persist; do
    target="/mnt"
    [ "$subvol" != "root" ] && target="/mnt/$subvol"
    sudo mount -o subvol="$subvol",compress=zstd,noatime /dev/mapper/cryptroot "$target"
done

# Mount EFI partition
sudo mount -t vfat "$EFI" /mnt/boot
# === END MOUNT ===

# Query user information
read -p "Enter desired hostname: " HOSTNAME
# timedatectl list-timezones
read -p "Enter desired time zone (e.g., America/Chicago): " TIMEZONE
read -p "Enter desired username: " USERNAME
read -s -p "Enter password: " PASSWORD
echo
read -s -p "Confirm password: " PASSWORD2
echo
if [ "$PASSWORD" != "$PASSWORD2" ]; then
  echo "Passwords do not match!" >&2
  exit 1
fi

# Generate hardware config
nixos-generate-config --root /mnt

# For NVIDIA configuration
NVIDIA_BLOCK='
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    cudaSupport = true;
    # For specific requirements, add deviceSections or busId options here
  };
  services.xserver.videoDrivers = [ "nvidia" ];
'

if grep -qi 'nvidia' /mnt/etc/nixos/hardware-configuration.nix || [ "$(lspci | grep -i 'nvidia' | wc -l)" -gt 0 ]; then
    sed -i "/^}/i ${NVIDIA_BLOCK}" /mnt/etc/nixos/configuration.nix
fi

CONFIG_TEMPLATE=./nixos/configuration-template.nix
FLAKE_TEMPLATE=./nixos/flake-template.nix
HOME_TEMPLATE=./nixos/home-template.nix

CONFIG_OUTPUT=./configuration.nix
FLAKE_OUTPUT=./flake.nix
HOME_FILE="/home/${USERNAME}/.config/home-manager/home.nix"

# Substitute variables into config template
sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|TIMEZONE|$TIMEZONE|g" \
    -e "s|USERNAME|$USERNAME|g" \
    -e "s|PASSWORD|$PASSWORD|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|USERNAME|$USERNAME|g" \
    "$FLAKE_TEMPLATE" > "$FLAKE_OUTPUT"

# Substitute and create user's home-manager config in their home directory
mkdir -p "$(dirname "${HOME_FILE}")"
sed "s|USERNAME|$USERNAME|g" "$HOME_TEMPLATE" > "$HOME_FILE"
chown "${USERNAME}:${USERNAME}" "$HOME_FILE"

# Clone your flake repo, if needed:
# git clone <your-config-repo> /mnt/etc/nixos

# (Assume disk partitioning is done; mount root at /mnt)
# Copy configs in place
cp "$CONFIG_OUTPUT" /mnt/etc/nixos/configuration.nix
cp "$FLAKE_OUTPUT" /mnt/etc/nixos/flake.nix

# Optionally copy session files:
# mkdir -p /mnt/etc/nixos/wayland-sessions
# cp ./wayland-sessions/*.desktop /mnt/etc/nixos/wayland-sessions/

echo "All configs are now in /mnt/etc/nixos/."
echo "Confirm partitions with: lsblk."
echo "Verify that /mnt/etc/nixos/hardware-configuration.nix exists."
echo "Verify that configuration.nix and flake.nix are templated correctly"
echo "Running the following should not return anything."
echo "  grep HOSTNAME /mnt/etc/nixos/configuration.nix"
echo "  grep TIMEZONE /mnt/etc/nixos/configuration.nix"
echo "  grep USERNAME /mnt/etc/nixos/configuration.nix"
echo "  grep PASSWORD /mnt/etc/nixos/configuration.nix"
echo "  grep HOSTNAME /mnt/etc/nixos/flake.nix"
echo "  grep USERNAME /mnt/etc/nixos/flake.nix"
echo "Confirm mount points with: mount | grep /mnt"
echo "---"
echo "All configs are now properly in /mnt/etc/nixos/. Run:"
echo "  nixos-install --flake /mnt/etc/nixos#$HOSTNAME"
echo "to complete installation. Then reboot and login as $USERNAME."

# Install with flakes:
# nixos-install --flake /mnt/etc/nixos#${HOSTNAME}
