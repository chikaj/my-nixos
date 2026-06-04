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
    docker-compose
    podman-compose

    # Developer environments
    devenv

    # GUI file manager
    thunar

    # CLI utilities
    fastfetch
    bat
    eza
    btop
    duf
    dust
    tldr

    # Media
    pavucontrol
    swayimg
    mpv

    # GUI utilities
    file-roller
    thunar-archive-plugin
    zathura
    qalculate-gtk
    font-manager
    blueman

    # Version control
    jujutsu
  ];
}
