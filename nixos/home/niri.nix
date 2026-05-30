{ config, pkgs, inputs, ... }:

{
  programs.niri = {
    package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    settings = {
      spawn-at-startup = [
        {
          command = [ "noctalia-shell" ];
        }
      ];

      window-rules = [
        {
          geometry-corner-radius = { top-left = 20.0; top-right = 20.0; bottom-right = 20.0; bottom-left = 20.0; };
          clip-to-geometry = true;
        }
      ];

      layer-rules = [
        {
          matches = [{
            namespace = "^noctalia-overview.*";
          }];
          place-within-backdrop = true;
        }
        {
          matches = [{
            namespace = "^noctalia-wallpaper.*";
          }];
          place-within-backdrop = true;
        }
      ];

      layout = {
        background-color = "transparent";
      };

      overview = {
        workspace-shadow.enable = false;
      };

      debug = {
        honor-xdg-activation-with-invalid-serial = true;
      };
    };
  };
}
