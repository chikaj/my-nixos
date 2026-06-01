{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Noctalia dependencies
    brightnessctl
    imagemagick
    python3
    git

    # Optional Noctalia dependencies
    cliphist
    wlsunset

    # Wayland utilities
    wl-clipboard
    grim
    slurp
    swappy
    wtype
    xdg-desktop-portal-gtk

    # File managers
    yazi
    superfile

    # Shortcut commands
    (pkgs.writeShellScriptBin "y" ''
      exec ${pkgs.yazi}/bin/yazi "$@"
    '')
    (pkgs.writeShellScriptBin "spf" ''
      exec ${pkgs.superfile}/bin/superfile "$@"
    '')

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.meslo-lg
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono
  ];
}
