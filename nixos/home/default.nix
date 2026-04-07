{ ... }:

{
  imports = [
    ./niri.nix
    ./noctalia.nix
    ./shell.nix
    ./editor.nix
    ./packages.nix
  ];

  home.stateVersion = "25.05";

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
