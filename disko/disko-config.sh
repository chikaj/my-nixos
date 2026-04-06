#!/usr/bin/env bash

set -euo pipefail
# set -a
# source .env
# set +a

# Disko and partitioning step:
echo "Enter your target device (e.g., /dev/nvme2n1):"
read DEVICENAME
if [ -z "$DEVICENAME" ]; then
    echo "Error: DEVICENAME is not set." >&2
    exit 1
fi

grep -v '^DEVICENAME=' .env > .env.tmp && mv .env.tmp .env
echo "DEVICENAME=$DEVICENAME" >> .env

echo
read -s -p "Enter your desired LUKS password: " LUKSPASS

echo
read -s -p "Confirm desired LUKS password: " LUKSPASS2
echo
if [ "$LUKSPASS" != "$LUKSPASS2" ]; then
  echo "LUKS passwords do not match!" >&2
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

echo "Disk partitioning complete. Proceed with NixOS installation."
