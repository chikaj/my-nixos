#!/usr/bin/env bash

echo "Enter your target device (e.g., /dev/nvme2n1):"
read DEVICENAME

echo "Enter your desired LUKS password:"
read -s LUKSPASS

# Write password to a temporary keyfile
echo -n "$LUKSPASS" > /tmp/secret.key

# Copy and modify template disko-config, replacing device name
sed "s|/dev/mydisk|$DEVICENAME|g" ./disko-config-template.nix > ./disko-config.nix

# Trigger disko with supplied config and password
sudo nix run github:nix-community/disko -- --mode disko ./disko-config.nix

# Remove temporary keyfile after partitioning for security
rm -f /tmp/secret.key

echo "Disk partitioning complete. Proceed with NixOS install steps."
