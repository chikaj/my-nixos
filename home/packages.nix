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

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.meslo-lg
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono

    # Container management
    podman-desktop

    # Developer environments
    devenv
  ];
}
