{ config, pkgs, ... }:

{
  imports = [
    ./niri.nix
    ./noctalia.nix
    ./shell.nix
    ./editor.nix
    ./flameshot.nix
    ./qgis.nix
    ./opencode.nix
    ./vivaldi.nix
    ./packages.nix
  ];

  home.stateVersion = "26.05";

  home.sessionVariables = {
    DISPLAY = ":0";
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
