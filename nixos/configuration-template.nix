{ config, pkgs, ... }:

let
  hostname = "HOSTNAME";       # Replace via bash script/template
  timezone = "TIMEZONE";       # Replace via bash script/template
  username = "USERNAME";       # Replace via bash script/template
  password = "PASSWORD";       # Replace via bash script/template

  customSessionsDir = "/etc/nixos/wayland-sessions";
  systemSessionsDir = "/run/current-system/sw/share/wayland-sessions";
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = hostname;
  time.timeZone = timezone;

  # User definition
  users.users.${username} = {
    isNormalUser = true;
    description = "Desktop Owner";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = password;
  };

  # Basic packages and DE/WM
  environment.systemPackages = with pkgs; [
    git wget curl htop vim ghostty cosmic-desktop cosmic-comp hyprland
  ];

  # Hyprland and Cosmic
  programs.hyprland.enable = true;
  services.desktopManager.cosmic.enable = true;

  # Tuigreet + greetd setup for session selection
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions /run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions";
        user = "greeter";
      };
    };
  };

  hardware.opengl.enable = true;
  hardware.nvidia.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # # Activation script to deploy custom session files for tuigreet
  #   system.activationScripts.customSessions = ''
  #     if [ -d ${customSessionsDir} ]; then
  #       echo "Copying custom session files to ${systemSessionsDir}..."
  #       cp -f ${customSessionsDir}/*.desktop ${systemSessionsDir}/
  #     fi
  #   '';

  # Memory optimization: ZRAM and swappiness
  services.zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Unlock LUKS early for initramfs
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-partlabel/cryptroot";  # your LUKS partition (from Disko)
      preLVM = true;
    };
  };

  # File system mounts (Btrfs subvolumes + EFI)
  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=root" "noatime" "compress=zstd" ];
    };
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };
    "/home" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=home" "noatime" "compress=zstd" ];
    };
    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=persist" "noatime" "compress=zstd" ];
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  # Swap file inside encrypted root
  swapDevices = [
    {
      device = "/swap/swapfile";  # will be created automatically by NixOS
      size = 256 * 1024 * 1024;    # GiB in KiB. Set to be equal to or greater than system RAM!
    }
  ];

  # Hibernation support
  boot.kernelParams = [ "resume=/swap/swapfile" ];

  system.stateVersion = "25.05"; # Set accordingly
}
