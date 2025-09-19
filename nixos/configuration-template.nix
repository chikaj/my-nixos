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
    initialPassword = password; # Remove after first boot
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

  system.stateVersion = "25.05"; # Set accordingly
}
