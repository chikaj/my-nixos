{ config, pkgs, inputs, ... }:

{
  programs.niri = {
    enable = true;
    package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };
}
