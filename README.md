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
   - Enter desired hostname
   - Enter timezone (e.g., `America/Chicago`)
   - Enter username
   - Enter user password (and confirm)
   - Whether the machine has an NVIDIA GPU
   - Whether to generate an SSH key (and your email if yes)

6. The script will:
   - Partition and encrypt the disk with Disko
   - Mount the filesystem
   - Generate hardware configuration
   - Copy the repo to `/mnt/etc/nixos/` (the installed system's config)
   - Create `hosts/<hostname>/default.nix` with per-machine values
   - Run `nixos-install --flake /mnt/etc/nixos#<hostname>`

7. Reboot and remove the USB:
   ```bash
   reboot
   ```

8. Save the new host config to the repo.
   `install.sh` already made an initial commit so the flake could evaluate, but
   you should commit the host config with a proper message and push:

   First, copy your SSH public key to GitHub at
   https://github.com/settings/keys:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   Then save the config:

   ```bash
   cd /etc/nixos
   git add hosts/<hostname>/
   git commit --amend -m "add <hostname> configuration"
   # If needed: git remote add origin https://github.com/<your-username>/my-nixos.git
   git push
   ```

   This uses `--amend` to replace the automatic "generated host config" commit
   with a descriptive message. On future changes, stage your files with
   `git add` and commit with `git commit -m "what changed"`, then `git push`.

9. To add new software that you want on **every** machine, for example the
    Vivaldi browser, create a new module in `home/`:

    For software that should only be on one machine, see step 10 instead.

    ```bash
    cat > /etc/nixos/home/vivaldi.nix << 'EOF'
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        vivaldi
        vivaldi-ffmpeg-codecs
      ];

      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = {
        "text/html" = "vivaldi.desktop";
        "x-scheme-handler/http" = "vivaldi.desktop";
        "x-scheme-handler/https" = "vivaldi.desktop";
        "x-scheme-handler/about" = "vivaldi.desktop";
        "x-scheme-handler/unknown" = "vivaldi.desktop";
        "application/pdf" = "vivaldi.desktop";
      };

      home.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };
    }
    EOF
    ```

    Add it to the imports in `home/default.nix`:

    ```bash
    # Edit /etc/nixos/home/default.nix and add ./vivaldi.nix to the imports list
    ```

    Stage the new files and rebuild with `--impure` to test without committing:

    ```bash
    cd /etc/nixos
    sudo git add home/vivaldi.nix home/default.nix
    sudo nixos-rebuild switch --impure
    ```

    Once it works, commit and push:

    ```bash
    sudo git commit -m "add vivaldi browser"
    sudo git push
    ```

10. To add software for a **single** machine (not shared), edit
    `machine-specific.nix` in that machine's host directory:

    ```bash
    cd /etc/nixos
    sudo -e hosts/<hostname>/machine-specific.nix
    ```

    Add packages to the list — for example:

    ```nix
    home.packages = with pkgs; [
      cuda
      some-heavy-app
    ];
    ```

    Rebuild and commit as usual:
    ```bash
    sudo nixos-rebuild switch
    sudo git commit -am "add machine-specific packages"
    sudo git push
    ```

11. After installing new software on one machine, update all machines by pulling
    and rebuilding:

    ```bash
    cd /etc/nixos && git pull
    sudo nixos-rebuild switch
    ```

    Changes to shared configs (`modules/`, `home/`) apply to all machines —
    other machines must `git pull` before rebuilding. Changes to host-specific
    configs (`hosts/<hostname>/`) apply only to that machine.

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
- Docker + Podman (container runtimes)

**Graphics:**
- NVIDIA drivers (if NVIDIA GPU detected)
- Wayland support

### Configuration Structure

```
├── flake.nix          # Multi-host flake (auto-discovers hosts/ directory)
├── hosts/             # Per-machine configs (one subdirectory per machine)
│   ├── <hostname>/
│   │   ├── default.nix          # hostname, timezone, user, UUIDs, module imports
│   │   ├── hardware.nix         # generated by nixos-generate-config
│   │   └── machine-specific.nix # packages unique to this machine only
│   └── ...
├── modules/           # Shared system configuration — applies to every machine
│   ├── 00-default.nix
│   ├── 02-hardware.nix
│   ├── 02-nvidia.nix
│   ├── 03-services.nix
│   ├── 04-wm.nix
│   ├── 05-boot.nix
│   └── 06-containers.nix
├── home/              # Shared user configuration — applies to every machine
│   ├── default.nix
│   ├── niri.nix
│   ├── noctalia.nix
│   ├── shell.nix
│   ├── editor.nix
│   └── packages.nix
├── disko-config.nix   # Disko disk layout template (device placeholder)
└── install.sh         # Generates host configs, runs disko + nixos-install
```

**How the split works:**
- **`modules/` and `home/`** — everything here applies to every machine running
  this flake. Add shared software, services, and config here.
- **`hosts/<hostname>/default.nix`** — per-machine system config (hostname,
  timezone, filesystems, NVIDIA). Edit by hand when needed.
- **`hosts/<hostname>/hardware.nix`** — auto-generated by `nixos-generate-config`.
  Regenerate if hardware changes.
- **`hosts/<hostname>/machine-specific.nix`** — packages installed only on that
  machine. Anything you don't want on your laptop goes here.
