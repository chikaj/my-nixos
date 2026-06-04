{ config, pkgs, inputs, ... }:

{
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  # XWayland for apps that need it (e.g. some Qt apps)
  programs.xwayland.enable = true;
}
