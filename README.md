# NixOS Installation Framework

A modular, secure, and flexible NixOS installation framework that separates disk configuration, system configuration, and installation into independent, reusable modules.

## 🏗️ Architecture Overview

```
my-nixos/
├── install.sh              # Main orchestrator script (ENTRY POINT)
├── modules/               # Modular installation components
│   ├── common.sh          # Shared utilities and functions
│   ├── disk.sh            # Disk partitioning and mounting
│   ├── config.sh          # Configuration generation and templating
│   └── nixos.sh           # NixOS system installation
├── templates/             # All configuration templates
│   ├── disko-config.nix   # Disk partitioning template
│   ├── configuration.nix   # System configuration template
│   ├── flake.nix          # Flake configuration template
│   ├── home.nix           # Home-manager template
│   └── wayland-sessions/  # Desktop session files
└── docs/                 # Detailed documentation
    ├── disk-setup.md       # Disk configuration guide
    ├── config-setup.md     # Configuration guide
    └── nixos-install.md   # Installation guide
```

## 📶 WiFi Connection (Optional for Laptop Users)

If you're installing on a laptop without an ethernet connection, you'll need to connect to WiFi before starting the installation. The NixOS live ISO includes NetworkManager for easy WiFi management.

### Connect to WiFi

1. **Check NetworkManager status:**
   ```bash
   systemctl status NetworkManager
   ```

2. **List available WiFi networks:**
   ```bash
   nmcli device wifi list
   ```
   Take note of the SSID for your desired network.

3. **Connect to your WiFi network:**
   ```bash
   sudo nmcli device wifi connect "SSID" password "YOUR_PASSWORD"
   ```
   Replace `SSID` with your network name and `YOUR_PASSWORD` with your WiFi password.

4. **Verify connection:**
   ```bash
   ping -c 3 google.com
   ```

### Troubleshooting WiFi

- **No WiFi adapter found**: Some laptops may require firmware installation. The installation framework includes automatic WiFi firmware setup.
- **Connection fails**: Try restarting NetworkManager: `sudo systemctl restart NetworkManager`
- **Hidden networks**: Use `nmcli device wifi connect SSID password "YOUR_PASSWORD" hidden yes`

**Note**: If WiFi firmware installation is required, you may need to reboot after the firmware is installed for the adapter to work properly.

## 🚀 Installation Workflow

### ⚠️ IMPORTANT: Installation Order

For a fresh NixOS installation, you MUST follow this order:

1. **Disk Setup** (Required first)
2. **Configuration Setup** (Requires mounted disks)
3. **NixOS Installation** (Requires configuration files)

## 🎯 Entry Point: install.sh

The `install.sh` script is your main entry point. It orchestrates all modules and provides multiple installation methods.

### 📋 Installation Methods

| Method | Command | When to Use |
|--------|---------|-------------|
| **Full** | `./install.sh full` | Complete guided installation (recommended for beginners) |
| **Quick** | `./install.sh quick` | Automated installation without confirmations |
| **Disk Only** | `./install.sh disk` | **Step 1**: Partition and mount filesystems |
| **Config Only** | `./install.sh config` | **Step 2**: Generate configuration files (requires completed Step 1) |
| **NixOS Only** | `./install.sh nixos` | **Step 3**: Install NixOS system (requires completed Step 2) |
| **Mount Only** | `./install.sh mount` | Mount existing filesystems (for recovery) |
| **Status** | `./install.sh status` | Show current system status |

## 🔧 Step-by-Step Installation

### Fresh NixOS Installation

```bash
# 1. Boot NixOS live USB
# 2. Clone repository
git clone <your-repo-url>
cd my-nixos

# 3. Complete installation (recommended)
./install.sh full

# OR step-by-step installation:
# ./install.sh disk    # Phase 1: Disk setup
# ./install.sh config   # Phase 2: Configuration setup  
# ./install.sh nixos    # Phase 3: NixOS installation
```

### Recovery/Debugging Workflow

```bash
# For recovery or debugging existing setup:
./install.sh status    # Check state
./install.sh mount     # Mount filesystems
./install.sh config    # Regenerate configuration
./install.sh nixos    # Reinstall system
```

## 🔄 Installation Flow Diagram

```
┌─────────────────┐
│   install.sh    │ ← START HERE
└────────┬──-──-──┘
         │
         ▼
┌───────────-──┐
│ Module Check │
└───────┬───-──┘
        │
        ▼
┌─────────────────────────────────────────-┐
│ Choose Command:                          │
│                                          │
│ full/quick ──► disk ──► config ──► nixos │
│ disk         ──► [STOP]                  │
│ config        ──► [ERROR - need disks]   │
│ nixos        ──► [ERROR - need config]   │
│ mount        ──► [STOP]                  │
│ status       ──► [STOP]                  │
└─────────────────────────────────────────-┘
```

## 🎯 Common Workflows

### 🟢 Beginner Workflow
```bash
# Complete guided installation
./install.sh full
```

### 🟡 Intermediate Workflow
```bash
# Step-by-step with control
./install.sh disk      # Setup disks
./install.sh config     # Configure system
./install.sh nixos      # Install NixOS
```

### 🔴 Advanced/Debug Workflow
```bash
# Individual module control
./modules/disk.sh setup      # Direct disk control
./modules/config.sh setup     # Direct config control
./modules/nixos.sh install   # Direct installation
```

## 🖥️ Hardware Profiles

Your modular installation supports flexible hardware configuration:

### **Hardware Profile Selection**
When running `./install.sh full` or `./install.sh config`, you'll see:
```bash
Hardware profile selection:
1. Auto-detect (recommended)    # Automatically detects NVIDIA
2. NVIDIA GPU                 # Forces NVIDIA configuration  
3. Non-NVIDIA GPU (Intel/AMD)   # Optimized for Intel/AMD
4. Generic/Minimal               # Basic configuration
```

### **Multi-Machine Setup**
```bash
# Desktop with NVIDIA
FORCE_NVIDIA=true ./install.sh quick

# Laptop with Intel graphics  
FORCE_NO_NVIDIA=true ./install.sh quick

# Minimal server setup
FORCE_GENERIC=true ./install.sh quick
```

### **Hardware-Specific Templates**
- `templates/hardware-specific/nvidia.nix` - Complete NVIDIA setup with CUDA
- `templates/hardware-specific/no-nvidia.nix` - Optimized Intel/AMD configuration

### **Use Cases**
- **Desktop with RTX 4090**: Choose "NVIDIA GPU" profile
- **Laptop with Intel iGPU**: Choose "Non-NVIDIA GPU" profile  
- **Mixed environment**: Use separate configurations per machine
- **Testing/CI**: Use "Generic/Minimal" profile

## 📋 Pre-Installation Requirements

### System Requirements
- **Hardware**: x86_64, UEFI firmware, 8GB+ RAM, 20GB+ storage
- **Software**: NixOS live USB, internet connection, sudo access
- **Environment**: Booted from NixOS live ISO
- **Network**: WiFi firmware may be needed for laptop installations

### Required Information
- **Target disk device** (e.g., `/dev/nvme0n1`)
- **LUKS encryption password** (for disk encryption)
- **System hostname** (e.g., `mynixos`)
- **Timezone** (e.g., `America/Chicago`)
- **Username** (e.g., `nate`)
- **User password** (for initial login)
- **WiFi firmware** (automatically installed if needed) 

### Optional Information
- **NVIDIA GPU** (auto-detected)
- **Custom hardware configuration**
- **Additional user accounts**

## 🛡️ Security Features

### Password Security
- **No persistent storage**: Passwords never written to configuration files
- **Secure handling**: Temporary keyfiles created with `chmod 600`
- **Immediate cleanup**: Sensitive data removed immediately after use
- **Separation**: LUKS and user passwords handled independently

### Filesystem Security
- **Full disk encryption**: LUKS encryption for entire system disk
- **Secure subvolumes**: Btrfs with compression and `noatime`
- **Proper permissions**: Appropriate file ownership and access rights

## 📚 Documentation

| Document | Purpose | Location |
|----------|---------|----------|
| **[disk-setup.md](docs/disk-setup.md)** | Complete disk partitioning and encryption guide | `docs/disk-setup.md` |
| **[config-setup.md](docs/config-setup.md)** | Configuration generation and templating guide | `docs/config-setup.md` |
| **[nixos-install.md](docs/nixos-install.md)** | NixOS installation and troubleshooting guide | `docs/nixos-install.md` |

## 🎯 Use Cases

### Personal Desktop Installation
```bash
# Quick desktop setup with Cosmic/Hyprland
./install.sh quick
```

### Server Installation
```bash
# Manual control for server setup
./install.sh disk
./install.sh config
./install.sh nixos
```

### Development/Testing
```bash
# Iterative development and testing
./install.sh disk     # Setup disks
# Modify templates/
./install.sh config    # Test configuration
./install.sh nixos     # Test installation
```

### System Recovery
```bash
# Recover existing installation
./install.sh status    # Check state
./install.sh mount     # Mount filesystems
./install.sh config    # Regenerate configuration
./install.sh nixos     # Reinstall system
```

## 🔍 Troubleshooting

### Common Issues

**"No LUKS partition found"**
- Solution: Run `./install.sh disk` to complete disk setup
- Check: `lsblk -f` to verify partitions

**"Configuration file not found"**
- Solution: Run `./install.sh config` after disk setup
- Check: `ls -la /mnt/etc/nixos/` for configuration files

**"Installation fails"**
- Solution: Run `./install.sh status` to verify requirements
- Check: Network connectivity, disk space, configuration syntax
- **WiFi Issue**: Reboot after firmware installation if needed

### Debug Commands
```bash
# Check system status
./install.sh status

# Verify modules work independently
./modules/nixos.sh verify

# Check mounts
mount | grep /mnt

# Inspect configuration
ls -la /mnt/etc/nixos/
```

## 🤝 Getting Started

### First Time Installation
```bash
# 1. Boot NixOS live USB
# 2. Clone repository
git clone <your-repo-url>
cd my-nixos

# 3. Run installation
./install.sh full

# 4. Follow prompts for:
#    - Select target disk
#    - Set LUKS password
#    - Configure hostname/timezone/username
#    - Confirm installation

# 5. Wait for completion
# 6. Reboot and enjoy NixOS!
```

### Module-Specific Help
```bash
# Get help for any module
./install.sh help
./modules/disk.sh help
./modules/config.sh help
./modules/nixos.sh help
```

---

**🎉 Ready to install NixOS?** 

```bash
# Start your modular NixOS installation
git clone <your-repo-url>
cd my-nixos
./install.sh full
```

For detailed guides, see `docs/` directory or use `./install.sh help`.
