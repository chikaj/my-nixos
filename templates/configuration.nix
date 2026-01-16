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
  users.users."${username}" = {
    isNormalUser = true;
    description = "Desktop Owner";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = password;
  };

  # Basic packages and DE/WM
  environment.systemPackages = with pkgs; [
    git wget curl htop vim ghostty hyprland
  ];

  # Hyprland and Cosmic
  programs.hyprland.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = false;

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

  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };
  # services.xserver.videoDrivers = [ "nvidia" ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # Memory optimization: ZRAM and swappiness

  zramSwap = {
    enable = true;
    # optional tuning:
    # algorithm = "lz4";         # or "zstd"
    # memoryPercent = 30;        # max % of RAM usable by zram
    # priority = 100;            # swap priority so zram is preferred
  };
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Network configuration for live ISO compatibility
  networking.networkmanager.enable = true;

  # Hardware support for WiFi
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # Unlock LUKS early for initramfs
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/mapper/cryptroot";
      preLVM = true;
    };
  };

  # Swap file inside encrypted root
  swapDevices = [
    {
      device = "/swap/swapfile";  # will be created automatically by NixOS
      size = 16384;    # GiB in KiB. Set to be equal to or greater than system RAM!
    }
  ];

  # Hibernation support
  boot.kernelParams = [ "resume=/swap/swapfile" ];

  system.stateVersion = "25.05"; # Set accordingly
}
