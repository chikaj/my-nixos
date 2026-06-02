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
    # Wayland env vars are set globally in niri.nix (NIXOS_OZONE_WL,
    # ELECTRON_OZONE_PLATFORM_HINT), so no wrapper needed here.
    pkgs.podman-desktop
    docker-compose
    podman-compose

    # Developer environments
    devenv

    # GUI file manager
    thunar

    # AI coding agent
    (pkgs.callPackage ../pkgs/opencode { })

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
    flameshot
    qalculate-gtk
    font-manager
    blueman

    # GIS
    (pkgs.qgis.override {
      withGrass = true;
      withServer = true;
    })

    # Version control
    jujutsu
  ];

  # Flameshot on Wayland needs UseGrimAdapter to avoid the deprecated DBus protocol
  xdg.configFile."flameshot/flameshot.ini" = {
    force = true; # override existing file if flameshot already created it
    text = ''
      [General]
      useGrimAdapter=true
    '';
  };

  # Opencode global config — per-project opencode.json in each repo overrides this.
  # Run `/connect` in the TUI to set up a provider (or edit providers here directly).
  xdg.configFile."opencode/opencode.json".text = ''
    {
      "$schema": "https://opencode.ai/config.json"
    }
  '';

  xdg.configFile."opencode/tui.json".text = ''
    {
      "$schema": "https://opencode.ai/tui.json"
    }
  '';
}
