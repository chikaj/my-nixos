# Configuration Setup Documentation

## Overview

The config module handles user configuration, template processing, and NixOS configuration file generation. It manages system settings, user accounts, and service configurations.

## Module: `modules/config.sh`

### Usage

```bash
# Full configuration setup
./modules/config.sh setup

# Show help
./modules/config.sh help
```

### Features

- **User configuration**: Hostname, timezone, user account setup
- **Template processing**: Dynamic substitution of configuration variables
- **Hardware detection**: Automatic NVIDIA configuration
- **Home-manager setup**: User environment configuration
- **Validation**: Comprehensive verification of generated configs

## Workflow

### 1. Prerequisites Check

The module verifies:
- Filesystems are mounted at `/mnt`
- Hardware configuration exists: `/mnt/etc/nixos/hardware-configuration.nix`

### 2. User Information Collection

Interactive prompts for system configuration:
```bash
Enter desired hostname: mynixos
Enter desired time zone (e.g., America/Chicago): America/Chicago
Enter desired username: nate
Enter password: ****
Confirm password: ****
```

### 3. Template Processing

The module processes multiple templates:
- **System configuration**: `/templates/configuration.nix`
- **Flake configuration**: `/templates/flake.nix`
- **Home-manager**: `/templates/home.nix`

### 4. Hardware Detection

Automatic NVIDIA detection and configuration:
- Scans PCI devices for NVIDIA hardware
- Adds appropriate kernel modules and drivers
- Configures CUDA support if applicable

### 5. File Deployment

Copies generated configurations to target system:
- `/mnt/etc/nixos/configuration.nix`
- `/mnt/etc/nixos/flake.nix`
- `/home/USERNAME/.config/home-manager/home.nix`

## Template Configuration

### System Template: `templates/configuration.nix`

Template variables:
- `HOSTNAME` - System hostname
- `TIMEZONE` - System timezone
- `USERNAME` - Primary user account
- `PASSWORD` - Initial user password

Key configuration sections:
```nix
{ config, pkgs, ... }:

let
  hostname = "HOSTNAME";       # Replaced by script
  timezone = "TIMEZONE";       # Replaced by script
  username = "USERNAME";       # Replaced by script
  password = "PASSWORD";       # Replaced by script
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = hostname;
  time.timeZone = timezone;

  users.users.${username} = {
    isNormalUser = true;
    description = "Desktop Owner";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = password;
  };

  # Additional system configuration...
}
```

### Flake Template: `templates/flake.nix`

Flake configuration with home-manager integration:
```nix
{
  description = "NixOS system with home-manager";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }:
    let
      hostname = "HOSTNAME";
      username = "USERNAME";
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.${username} = import ./home.nix;
          }
        ];
      };
    };
}
```

### Home Manager Template: `templates/home.nix`

User environment configuration:
```nix
{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # User packages
    ghostty
    helix
    nushell
    starship
  ];

  # Program configurations...
}
```

## Hardware Detection

### NVIDIA Configuration

When NVIDIA hardware is detected, the module adds:
```nix
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
  cudaSupport = true;
};
services.xserver.videoDrivers = [ "nvidia" ];
```

Detection methods:
- PCI device scanning: `lspci | grep -qi 'nvidia'`
- Hardware configuration analysis
- Manual override available

## Validation and Verification

### Template Verification

The module validates processed templates:
- Checks for unsubstituted placeholders
- Verifies syntax correctness
- Ensures required configurations are present

Verification commands:
```bash
# Should return nothing if templates processed correctly
grep HOSTNAME /mnt/etc/nixos/configuration.nix
grep TIMEZONE /mnt/etc/nixos/configuration.nix
grep USERNAME /mnt/etc/nixos/configuration.nix
grep PASSWORD /mnt/etc/nixos/configuration.nix
```

### Configuration Validation

Post-deployment verification:
- File existence checks
- Syntax validation
- Mount point verification
- Hardware configuration consistency

## Security Considerations

### Password Handling

- Initial password set via `initialPassword` (not stored in configuration)
- Passwords are written to configuration only during installation
- No password persistence in generated files
- Post-installation password changes required for security

### File Permissions

- Home-manager configuration owned by user
- System files with appropriate permissions
- Secure temporary file handling

## Session Configuration

### Wayland Sessions

Desktop session files are copied from `templates/wayland-sessions/`:
- `cosmic.desktop` - Cosmic Desktop Environment
- `hyprland.desktop` - Hyprland Window Manager

Session deployment:
```bash
mkdir -p /mnt/etc/nixos/wayland-sessions
cp templates/wayland-sessions/*.desktop /mnt/etc/nixos/wayland-sessions/
```

## Troubleshooting

### Common Issues

**Template substitution failures**
- Verify template files exist
- Check variable names in templates
- Ensure proper quoting in sed commands

**Permission errors**
- Verify filesystems are mounted
- Check directory permissions
- Ensure sudo access for system files

**Hardware detection issues**
- Manual NVIDIA configuration available
- Check hardware configuration file
- Verify PCI device detection

### Debugging Commands

Check template processing:
```bash
# Verify template exists
ls -la templates/configuration.nix

# Check generated configuration
cat /mnt/etc/nixos/configuration.nix | grep -E "(hostname|timezone|users)"
```

Validate configuration:
```bash
# Test configuration syntax
sudo nixos-rebuild build --no-build-nix --flake /mnt/etc/nixos#test
```

Check hardware detection:
```bash
# List PCI devices
lspci | grep -i vga

# Check hardware configuration
cat /mnt/etc/nixos/hardware-configuration.nix
```

## Integration

### Module Dependencies

The config module requires:
- **Disk module**: Mounted filesystems at `/mnt`
- **NixOS live environment**: `nixos-generate-config` availability

### Module Outputs

The config module produces:
- **System configuration**: `/mnt/etc/nixos/configuration.nix`
- **Flake configuration**: `/mnt/etc/nixos/flake.nix`
- **Home configuration**: `/home/USERNAME/.config/home-manager/home.nix`
- **Session files**: `/mnt/etc/nixos/wayland-sessions/`

## Best Practices

1. **Review generated configurations** before installation
2. **Test hardware detection** for specialized setups
3. **Verify user information** for correctness
4. **Backup important data** before system installation
5. **Document custom configurations** for future reference
6. **Ensure network connectivity** before starting installation
7. **Test WiFi firmware** if using wireless on live ISO

### Network Setup Tips

**Before Installation:**
- Test network connectivity on live ISO
- If using WiFi, expect automatic firmware installation
- Consider ethernet for more reliable connection

**During Installation:**
- Watch for WiFi firmware installation messages
- Verify connectivity before proceeding with NixOS install
- Use `./install.sh status` to check network state

**Common WiFi Issues:**
- Some adapters may require specific firmware packages
- May need reboot after firmware installation
- Legacy adapters may need additional configuration

