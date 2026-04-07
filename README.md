## NixOS Installation with Niri, Noctalia, and Btrfs

### Prerequisites

- NixOS live USB (minimal ISO)
- Target machine with UEFI and desired disk(s)

### Installation Steps

1. Boot the NixOS live USB. You will have a shell prompt as the `nixos` user with sudo privileges.

2. Inspect available disks:
   ```bash
   lsblk
   ```

3. Clone this repository:
   ```bash
   git clone https://github.com/chikaj/my-nixos.git
   cd my-nixos
   ```

4. Run the installer:
   ```bash
   ./install.sh
   ```

5. Follow the prompts:
   - Enter target device (e.g., `/dev/nvme2n1`)
   - Enter LUKS encryption password (and confirm)
   - Enter desired hostname
   - Enter timezone (e.g., `America/Chicago`)
   - Enter username
   - Enter user password (and confirm)

6. The script will:
   - Partition and encrypt the disk with Disko
   - Mount the filesystem
   - Generate hardware configuration
   - Copy and configure all NixOS modules
   - Run `nixos-install`

7. Reboot and remove the USB:
   ```bash
   reboot
   ```

### What Gets Installed

**Desktop Environment:**
- Niri (scrollable-tiling Wayland compositor)
- Noctalia (desktop shell with widgets and theming)

**Applications:**
- Ghostty (terminal)
- Nushell (shell)
- Helix (editor)
- Zed (modern code editor)
- Starship (prompt)
- Superfile (file picker)

**Services:**
- Greetd + Tuigreet (login manager)
- PipeWire (audio)
- XDG Portal (file dialogs)
- Power Profiles Daemon + UPower (power management)

**Graphics:**
- NVIDIA drivers (if NVIDIA GPU detected)
- Wayland support

### Configuration Structure

```
nixos/
├── modules/           # System configuration
│   ├── 00-default.nix
│   ├── 01-user.nix
│   ├── 02-hardware.nix
│   ├── 03-services.nix
│   ├── 04-wm.nix
│   └── 05-boot.nix
└── home/              # Home-manager configuration
    ├── niri.nix
    ├── noctalia.nix
    ├── shell.nix
    ├── editor.nix
    └── packages.nix
```

### Post-Installation

After first boot, you can update the configuration:

```bash
cd /etc/nixos
git remote set-url origin <your-repo-url>
git push
```

Edit files in `/etc/nixos/` and rebuild:
```bash
sudo nixos-rebuild switch
```
