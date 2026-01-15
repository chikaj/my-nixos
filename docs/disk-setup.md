# Disk Setup Documentation

## Overview

The disk module handles disk partitioning, LUKS encryption, and filesystem mounting using disko. It provides a secure way to set up Btrfs subvolumes with LUKS encryption.

## Module: `modules/disk.sh`

### Usage

```bash
# Full disk setup (partition and mount)
./modules/disk.sh setup

# Mount existing filesystems only
./modules/disk.sh mount

# Show help
./modules/disk.sh help
```

### Features

- **Secure partitioning**: Uses disko for declarative disk management
- **LUKS encryption**: Full disk encryption with password protection
- **Btrfs subvolumes**: Separate subvolumes for root, nix, home, persist
- **EFI support**: Automatic EFI partition detection and mounting
- **Security**: Temporary password files are immediately removed

## Workflow

### 1. Disk Selection

The module prompts for the target device:
```bash
Available devices:
NAME   SIZE MODEL
sda    500G Samsung SSD 860
nvme0n1 1T Samsung SSD 970

Enter your target device (e.g., /dev/nvme2n1): /dev/nvme0n1
```

### 2. LUKS Password

Secure password input with confirmation:
```bash
Enter your desired LUKS password: ****
Confirm LUKS password: ****
```

### 3. Disk Partitioning

The module:
- Creates disko configuration from template
- Runs disko with LUKS encryption
- Sets up Btrfs subvolumes:
  - `root` → `/`
  - `nix` → `/nix`
  - `home` → `/home`
  - `persist` → `/persist`
- Mounts EFI partition to `/boot`

### 4. Filesystem Mounting

Automatic detection and mounting:
- LUKS partition detection
- EFI partition identification
- Subvolume mounting with compression
- Security-optimized mount options

## Template Configuration

### Disko Template: `templates/disko-config.nix`

The disko configuration template supports:
- Custom device specification
- EFI System Partition (512MB)
- LUKS-encrypted Btrfs filesystem
- Multiple subvolumes for system organization

Key features:
```nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mydisk"; # Replaced by script
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              label = "cryptroot";
              content = {
                type = "luks";
                name = "cryptroot";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    root = { mountpoint = "/"; };
                    nix = { mountpoint = "/nix"; };
                    home = { mountpoint = "/home"; };
                    persist = { mountpoint = "/persist"; };
                    log = { mountpoint = "/var/log"; };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
```

## Security Considerations

### Password Handling
- Passwords are never written to disk
- Temporary keyfiles are created with `chmod 600`
- Keyfiles are immediately removed after use
- No password storage in state files

### State Management
Disk state is saved to `/tmp/disk-state.json` (without passwords):
```json
{
  "device": "/dev/nvme0n1",
  "luks_device": "/dev/mapper/cryptroot",
  "efi_partition": "/dev/nvme0n1p1",
  "mount_points": {
    "root": "/mnt",
    "boot": "/mnt/boot",
    "nix": "/mnt/nix",
    "home": "/mnt/home",
    "persist": "/mnt/persist"
  },
  "disks_ready": true
}
```

## Recovery and Debugging

### Mount Existing Filesystems

If partitioning was completed but the system rebooted:
```bash
./modules/disk.sh mount
```

This will:
- Detect existing partitions
- Prompt for device selection
- Unlock LUKS container
- Mount all subvolumes

### Manual Verification

Check partition layout:
```bash
lsblk -f
```

Verify mount points:
```bash
mount | grep /mnt
```

Check LUKS status:
```bash
sudo cryptsetup status cryptroot
```

## Troubleshooting

### Common Issues

**"No LUKS partition found"**
- Verify device selection
- Check if disko completed successfully
- Use `lsblk -f` to verify partition types

**"No EFI partition found"**
- Ensure disk partitioning completed
- Verify EFI partition is formatted as vfat
- Check partition flags with `fdisk -l`

**Mount failures**
- Ensure LUKS container is unlocked
- Check for existing mounts in `/mnt`
- Verify Btrfs subvolume creation

### Recovery Commands

Unlock LUKS manually:
```bash
sudo cryptsetup open /dev/nvme0n1p2 cryptroot
```

Mount manually:
```bash
sudo mount -o subvol=root,compress=zstd,noatime /dev/mapper/cryptroot /mnt
sudo mount -o subvol=nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home
sudo mount /dev/nvme0n1p1 /mnt/boot
```

## Integration

The disk module is designed to work with other modules:
- **Config module**: Expects mounted filesystems at `/mnt`
- **NixOS module**: Requires configuration files in `/mnt/etc/nixos`
- **Main orchestrator**: Coordinates sequential execution

## Best Practices

1. **Backup important data** before partitioning
2. **Verify device selection** - disko operations are destructive
3. **Use strong passwords** for LUKS encryption
4. **Test mount functionality** before proceeding to configuration
5. **Keep the LUKS password** secure and accessible

## Next Steps

After successful disk setup:

1. Run configuration setup:
   ```bash
   ./modules/config.sh setup
   ```

2. Install NixOS:
   ```bash
   ./modules/nixos.sh install
   ```

3. Or use the orchestrator:
   ```bash
   ./install.sh full
   ```
