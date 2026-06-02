#!/usr/bin/env bash

set -euo pipefail

# === DISK SETUP ===
echo "Enter your target device (e.g., /dev/nvme2n1):"
read DEVICENAME
DEVICENAME=$(echo "$DEVICENAME" | tr -d '\n')
if [ -z "$DEVICENAME" ]; then
    echo "Error: DEVICENAME is not set." >&2
    exit 1
fi

sed "s|/dev/mydisk|$DEVICENAME|g" ./disks/default.nix > ./disks/_tmp.nix

sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount ./disks/_tmp.nix

echo "Disk partitioning complete. Proceeding with NixOS install."

# === DETECT PARTITIONS ===
CRYPTROOT=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$3=="crypto_LUKS"{print "/dev/" $1}' | head -n1)
if [ -z "$CRYPTROOT" ]; then
    echo "Error: No LUKS partition found." >&2
    exit 1
fi

EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln "$DEVICENAME" | awk '$2=="part" && $3=="vfat" {print "/dev/" $1}' | head -n1)
if [ -z "$EFI" ]; then
    EFI=$(lsblk -o NAME,TYPE,FSTYPE -ln -p | awk '$3=="vfat"{print $1}' | head -n1)
fi
if [ -z "$EFI" ]; then
    echo "Error: No EFI partition found." >&2
    exit 1
fi

if ! mount | grep -q "/mnt "; then
    sudo cryptsetup open "$CRYPTROOT" cryptroot
fi

sudo mkdir -p /mnt/{etc,nix,home,persist,boot}
sudo mkdir -p /mnt/{etc/nixos,var/log}

for subvol in root nix home persist log; do
    target="/mnt"
    [ "$subvol" = "log" ] && target="/mnt/var/log"
    [ "$subvol" != "root" ] && [ "$subvol" != "log" ] && target="/mnt/$subvol"
    sudo mount -o subvol="$subvol",compress=zstd,noatime /dev/mapper/cryptroot "$target"
done

sudo mount -t vfat "$EFI" /mnt/boot

# === DETECT UUIDs ===
BOOTUUID=$(sudo blkid -s UUID -o value "$EFI" 2>/dev/null || echo "")
if [ -z "$BOOTUUID" ]; then
    echo "Error: Could not determine EFI partition UUID." >&2
    exit 1
fi
CRYPTUUID=$(sudo blkid -s UUID -o value "$CRYPTROOT" 2>/dev/null || echo "")
if [ -z "$CRYPTUUID" ]; then
    echo "Error: Could not determine LUKS partition UUID." >&2
    exit 1
fi

# === USER INPUT ===
read -p "Enter desired hostname: " HOSTNAME
HOSTNAME=$(echo "$HOSTNAME" | tr -d '\n')
if [ -z "$HOSTNAME" ]; then
    echo "Error: HOSTNAME is not set." >&2
    exit 1
fi

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
  echo "Passwords do not match!" >&2
  exit 1
fi

read -p "Does this machine have an NVIDIA GPU? (y/N): " HAS_NVIDIA
HAS_NVIDIA=$(echo "$HAS_NVIDIA" | tr -d '\n')

read -p "Generate SSH key for GitHub? (y/N): " HAS_SSH
HAS_SSH=$(echo "$HAS_SSH" | tr -d '\n')
if [ "$HAS_SSH" = "y" ] || [ "$HAS_SSH" = "Y" ]; then
    read -p "Enter email for SSH key: " SSH_EMAIL
    SSH_EMAIL=$(echo "$SSH_EMAIL" | tr -d '\n')
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f /tmp/id_ed25519 -N "" 2>/dev/null
    echo ""
    echo "=== PUBLIC SSH KEY (add this to GitHub: https://github.com/settings/keys) ==="
    cat /tmp/id_ed25519.pub
    echo "============================================================================="
    echo ""
fi

# === GENERATE HARDWARE CONFIG ===
sudo nixos-generate-config --root /mnt --no-filesystems

# === COPY REPO TO TARGET ===
sudo rsync -a --exclude='.DS_Store' ./ /mnt/etc/nixos/

# === CREATE HOST CONFIG ===
sudo mkdir -p "/mnt/etc/nixos/hosts/$HOSTNAME"

sudo mv /mnt/etc/nixos/hardware-configuration.nix "/mnt/etc/nixos/hosts/$HOSTNAME/hardware.nix"

sudo tee "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix" > /dev/null << 'NIXEOF'
{ lib, pkgs, ... }:

{
  networking.hostName = "HOSTNAME";
  time.timeZone = "TIMEZONE";

  users.users.USERNAME = {
    isNormalUser = true;
    description = "Desktop Wizard";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.nushell;
    initialPassword = "PASSWORD";
  };

  home-manager.users.USERNAME = import ../../home;

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/CRYPTUUID";
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };
    "/home" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" "noatime" ];
    };
    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=persist" "compress=zstd" "noatime" ];
    };
    "/var/log" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/BOOTUUID";
      fsType = "vfat";
    };
  };

  imports = [
    ../../modules/00-default.nix
    ../../modules/02-hardware.nix
NVIDIA_LINE
    ../../modules/03-services.nix
    ../../modules/04-wm.nix
    ../../modules/05-boot.nix
    ./hardware.nix
  ];
}
NIXEOF

# Substitute values into the host config
sudo sed -i "s|HOSTNAME|$HOSTNAME|g" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
sudo sed -i "s|TIMEZONE|$TIMEZONE|g" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
sudo sed -i "s|USERNAME|$USERNAME|g" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
sudo sed -i "s|PASSWORD|$PASSWORD|g" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
sudo sed -i "s|BOOTUUID|$BOOTUUID|g" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
sudo sed -i "s|CRYPTUUID|$CRYPTUUID|g" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"

# Handle NVIDIA import
if [ "$HAS_NVIDIA" = "y" ] || [ "$HAS_NVIDIA" = "Y" ]; then
    sudo sed -i "s|NVIDIA_LINE|    ../../modules/02-nvidia.nix|" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
else
    sudo sed -i "/NVIDIA_LINE/d" "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"
fi

rm ./disks/_tmp.nix

echo "Configs written to /mnt/etc/nixos/"
echo "Host config: hosts/$HOSTNAME/default.nix"

# === LOCK AND INSTALL ===
sudo nix --extra-experimental-features 'nix-command flakes' flake lock /mnt/etc/nixos

# Commit so the git tree is clean for flake evaluation
sudo git -C /mnt/etc/nixos add -A
sudo git -C /mnt/etc/nixos \
  -c user.name="nixos-install" \
  -c user.email="nixos@local" \
  commit -m "generated host config for $HOSTNAME"
sudo nixos-install --flake /mnt/etc/nixos#"$HOSTNAME" --no-root-passwd

# Remove initialPassword from host config (safe to commit after this)
sudo sed -i '/initialPassword/d' "/mnt/etc/nixos/hosts/$HOSTNAME/default.nix"

# Fix .git ownership so the user can push from the installed system
sudo nixos-enter --root /mnt -c "chown -R $USERNAME: /etc/nixos/.git" 2>/dev/null || true

# Deploy SSH key and switch remote to SSH
if [ "$HAS_SSH" = "y" ] || [ "$HAS_SSH" = "Y" ]; then
    sudo mkdir -p "/mnt/home/$USERNAME/.ssh"
    sudo cp /tmp/id_ed25519 "/mnt/home/$USERNAME/.ssh/"
    sudo cp /tmp/id_ed25519.pub "/mnt/home/$USERNAME/.ssh/"
    sudo nixos-enter --root /mnt -c "chown -R $USERNAME: /home/$USERNAME/.ssh && chmod 600 /home/$USERNAME/.ssh/id_ed25519 && chmod 644 /home/$USERNAME/.ssh/id_ed25519.pub" 2>/dev/null || true
    sudo git -C /mnt/etc/nixos remote set-url origin git@github.com:chikaj/my-nixos.git
    rm -f /tmp/id_ed25519 /tmp/id_ed25519.pub
fi

echo ""
echo "Installation complete!"
echo ""
echo "To save this host config to the repo, run on the installed system:"
echo "  cd /etc/nixos"
echo "  git add hosts/$HOSTNAME/"
echo "  git commit --amend -m 'add $HOSTNAME configuration'"
echo "  # If needed: git remote add origin <your-repo-url>"
echo "  git push"
