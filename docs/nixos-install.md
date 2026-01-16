# NixOS Installation Documentation

## Overview

The NixOS module handles the final installation phase of the NixOS system. It verifies system requirements, runs the NixOS installer, and provides post-installation verification and guidance.

## Module: `modules/nixos.sh`

### Usage

```bash
# Full installation with confirmation
./modules/nixos.sh install

# Quick installation without confirmation
./modules/nixos.sh quick

# Verify system requirements only
./modules/nixos.sh verify

# Show help
./modules/nixos.sh help
```

### Features

- **Requirement verification**: Ensures all prerequisites are met
- **Installation preview**: Shows what will be installed before proceeding
- **Confirmation prompts**: Prevents accidental installations
- **Post-installation verification**: Validates successful installation
- **Guidance**: Provides next steps for system setup

## Workflow

### 1. Prerequisites Check

The module verifies:
- Filesystems are mounted at `/mnt`
- Configuration files exist:
  - `/mnt/etc/nixos/configuration.nix`
  - `/mnt/etc/nixos/flake.nix`
  - `/mnt/etc/nixos/hardware-configuration.nix`

### 2. Installation Preview

Shows comprehensive preview:
```bash
=== Installation Preview ===

Target device: /dev/nvme0n1
Hostname: mynixos
Timezone: America/Chicago
Username: nate

Mount points:
/dev/nvme0n1p2 on /mnt type btrfs (rw,relatime,compress=zstd:3)
/dev/nvme0n1p1 on /mnt/boot type vfat (rw,relatime)

Configuration files:
-rw-r--r-- 1 root root 4.2K configuration.nix
-rw-r--r-- 1 root root 1.1K flake.nix
-rw-r--r-- 1 root root 2.8K hardware-configuration.nix
```

### 3. Installation Process

Runs NixOS installation:
```bash
sudo nixos-install --flake /mnt/etc/nixos#hostname
```

### 4. Post-Installation Verification

Validates installation success:
- System profiles existence
- Bootloader files
- Configuration deployment

## Installation Methods

### Standard Installation

Interactive installation with confirmations:
```bash
./modules/nixos.sh install
```

Process:
1. Requirement verification
2. Installation preview
3. User confirmation
4. Installation execution
5. Post-installation verification
6. Final instructions

### Quick Installation

Non-interactive installation for automation:
```bash
./modules/nixos.sh quick
```

Process:
1. Requirement verification
2. Installation execution
3. Post-installation verification
4. Final instructions

### Verification Only

Check if system is ready for installation:
```bash
./modules/nixos.sh verify
```

## Configuration Validation

### Required Files

The module requires specific configuration files:

#### `/mnt/etc/nixos/configuration.nix`
System configuration with:
- Hostname settings
- User configuration
- Service definitions
- Hardware support

#### `/mnt/etc/nixos/flake.nix`
Flake configuration with:
- System definition
- Home-manager integration
- Input sources

#### `/mnt/etc/nixos/hardware-configuration.nix`
Hardware-specific configuration:
- Kernel modules
- File system settings
- Device configurations

### Validation Checks

The module performs comprehensive validation:

```bash
# Check if partitions are mounted
mount | grep -q "/mnt "

# Verify configuration files exist
test -f /mnt/etc/nixos/configuration.nix
test -f /mnt/etc/nixos/flake.nix
test -f /mnt/etc/nixos/hardware-configuration.nix

# Validate configuration syntax
nix-instantiate --parse /mnt/etc/nixos/configuration.nix
nix-instantiate --parse /mnt/etc/nixos/flake.nix
```

## Installation Process

### NixOS Installation Command

The core installation command:
```bash
sudo nixos-install --flake /mnt/etc/nixos#hostname
```

What this does:
1. Builds system configuration
2. Downloads required packages
3. Installs bootloader
4. Sets up system services
5. Creates user accounts
6. Configures system settings

### Installation Steps

1. **Configuration Evaluation**: Nix evaluates the system configuration
2. **Package Download**: Downloads all required packages
3. **System Build**: Builds the complete system
4. **Installation**: Copies files to target system
5. **Bootloader Setup**: Installs and configures bootloader
6. **Activation**: Sets up initial system state

### Expected Output

Successful installation output:
```
building the system configuration...
copying channels...
installing the bootloader...
setting up /etc...
creating /nix/var/nix/profiles/system...
...
installation finished successfully!
```

## Post-Installation Verification

### System Verification

The module verifies installation success:

#### Profile Verification
```bash
# Check system profiles
ls -la /mnt/nix/var/nix/profiles/system
```

#### Bootloader Verification
```bash
# Check bootloader files
ls -la /mnt/boot/EFI/BOOT/BOOTX64.EFI
ls -la /mnt/boot/EFI/nixos/
```

#### Configuration Verification
```bash
# Verify configuration deployment
cat /mnt/etc/nixos/configuration.nix
```

### Success Indicators

Installation considered successful when:
- System profiles exist
- Bootloader files are present
- No errors during installation
- All configuration files are in place

## Final Instructions

### Installation Complete Message

```bash
=== Installation Complete ===

✅ NixOS has been successfully installed!

Next steps:
1. Remove installation media
2. Reboot system
3. Login with your username and password

After first boot:
- Update your system: sudo nixos-rebuild switch --update
- Explore your configuration in /etc/nixos/
- Configure additional users and services as needed

Installation process complete!
```

### Post-Installation Tasks

After first boot:

1. **System Update**
   ```bash
   sudo nixos-rebuild switch --update
   ```

2. **Explore Configuration**
   ```bash
   ls -la /etc/nixos/
   cat /etc/nixos/configuration.nix
   ```

3. **User Management**
   ```bash
   # Change initial password
   passwd
   
   # Add additional users if needed
   sudo nixos-rebuild switch
   ```

4. **Service Configuration**
   ```bash
   # Enable additional services
   sudo systemctl enable <service>
   
   # Check system status
   systemctl status
   ```

## Troubleshooting

### Common Issues

#### "Configuration file not found"
- Run config module first
- Verify filesystems are mounted
- Check file paths and permissions

#### "Hardware configuration not found"
- Generate hardware config with `nixos-generate-config`
- Verify disk module completed successfully
- Check /mnt/etc/nixos/ directory

#### Installation fails during build
- Check configuration syntax errors
- Verify flake inputs are accessible
- Ensure sufficient disk space
- Check network connectivity

#### Bootloader installation fails
- Verify EFI partition is mounted
- Check EFI partition format (should be vfat)
- Ensure secure boot settings are compatible

### Debug Commands

#### Manual Configuration Check
```bash
# Test configuration syntax
sudo nixos-rebuild build --no-build-nix --flake /mnt/etc/nixos#test

# Check flake evaluation
nix flake check /mnt/etc/nixos

# Inspect hardware configuration
cat /mnt/etc/nixos/hardware-configuration.nix
```

#### Manual Installation
If automatic installation fails:
```bash
# Manual installation steps
sudo nixos-install --flake /mnt/etc/nixos#hostname --option sandbox false
```

#### Log Analysis
```bash
# Check installation logs
journalctl -u nixos-installation.service

# Check Nix daemon logs
journalctl -u nix-daemon.service
```

### Recovery Scenarios

#### Partial Installation
If installation fails partway:
1. Unmount filesystems: `sudo umount -R /mnt`
2. Remount with disk module: `./modules/disk.sh mount`
3. Retry configuration: `./modules/config.sh setup`
4. Retry installation: `./modules/nixos.sh install`

#### Boot Issues
If system doesn't boot after installation:
1. Boot from NixOS live USB
2. Mount filesystems: `./modules/disk.sh mount`
3. Check bootloader: `ls -la /mnt/boot/EFI/`
4. Reinstall bootloader: `sudo nixos-install --no-root-passwd`

## Integration

### Module Dependencies

The NixOS module requires:
- **Disk module**: Mounted filesystems at `/mnt`
- **Config module**: Generated configuration files

### Module Outputs

The NixOS module produces:
- **Installed system**: Complete NixOS installation
- **Bootloader**: Configured bootloader for system boot
- **User accounts**: Created and configured user accounts

### Orchestration

With main orchestrator:
```bash
# Full installation
./install.sh full

# NixOS installation only
./install.sh nixos

# Quick installation
./install.sh quick
```

## Best Practices

1. **Verify before installing**: Always check requirements first
2. **Review configuration**: Check generated files before installation
3. **Backup data**: Ensure important data is backed up
4. **Test configuration**: Validate configuration syntax
5. **Monitor installation**: Watch for errors during installation
6. **Document changes**: Keep track of configuration modifications

## Automation

### Scripted Installation

For automated deployments:
```bash
#!/bin/bash
# Automated NixOS installation

# Check requirements
./modules/nixos.sh verify || exit 1

# Install without confirmation
./modules/nixos.sh quick
```

### Integration with CI/CD

For automated system deployment:
1. Use configuration management for templates
2. Validate configurations before deployment
3. Use quick installation for automation
4. Implement rollback procedures
5. Monitor deployment success

## Advanced Topics

### Custom Installation Options

The nixos-install command supports additional options:
```bash
sudo nixos-install --flake /mnt/etc/nixos#hostname \
  --no-root-passwd \
  --option sandbox false \
  --cores $(nproc)
```

### Multi-Boot Configurations

For multi-boot systems:
1. Ensure proper EFI partition setup
2. Configure bootloader correctly
3. Verify partition scheme compatibility
4. Test boot order after installation

### Remote Installation

For remote server installation:
1. Use SSH-based installation
2. Ensure network connectivity
3. Configure remote access in advance
4. Plan for bootloader configuration

## Security Considerations

### Installation Security

- Verify downloaded packages integrity
- Use secure connection for flake inputs
- Review configuration for security settings
- Change initial passwords after first boot

### Post-Installation Security

1. **Password Management**
   ```bash
   # Change initial password
   passwd
   
   # Set up SSH keys
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   # Add authorized keys
   ```

2. **System Updates**
   ```bash
   # Update system packages
   sudo nixos-rebuild switch --update
   
   # Check for security updates
   nix-channel --update nixos-unstable
   ```

3. **Service Configuration**
   ```bash
   # Review running services
   systemctl list-units --type=service
   
   # Disable unnecessary services
   sudo systemctl disable <service>
   ```

## Performance Optimization

### Installation Performance

To speed up installation:
```bash
# Use more cores
sudo nixos-install --flake /mnt/etc/nixos#hostname --cores $(nproc)

# Use binary cache
export NIX_CONFIG="experimental-features = nix-command flakes"
export NIX_ACCEPTED_KEYS="cache.nixos.org-1"
```

### System Performance

Post-installation optimization:
```bash
# Optimize Btrfs filesystem
echo "fileSystems.\"/\".options = [ \"compress=zstd\" ];" >> /etc/nixos/configuration.nix

# Rebuild with optimizations
sudo nixos-rebuild switch
```

## Conclusion

The NixOS installation module provides a robust, secure, and flexible way to complete your NixOS system setup. It includes comprehensive verification, clear progress indication, and helpful guidance for post-installation tasks.

By following the documented workflows and best practices, you can successfully install and configure NixOS systems for various use cases, from personal desktops to server deployments.

The modular design ensures that each installation phase is independent, testable, and maintainable, while the orchestrator script provides convenient access to the complete installation workflow.
