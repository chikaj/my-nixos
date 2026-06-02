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
    # Include the original package for its .desktop file (launcher integration);
    # the wrapper below shadows its bin/ in PATH with the OZONE_WL=1 fix.
    (pkgs.symlinkJoin {
      name = "podman-desktop-wrapped";
      paths = [
        pkgs.podman-desktop
        (pkgs.writeShellScriptBin "podman-desktop" ''
          export NIXOS_OZONE_WL=1
          # ELECTRON_OZONE_PLATFORM_HINT is the native Electron var for Wayland;
          # NIXOS_OZONE_WL is nixpkgs-specific and doesn't reach bundled runtimes.
          export ELECTRON_OZONE_PLATFORM_HINT=auto
          exec ${pkgs.podman-desktop}/bin/podman-desktop "$@"
        '')
      ];
    })
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
