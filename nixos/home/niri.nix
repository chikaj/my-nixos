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

      window-rule = {
        geometry-corner-radius = 20;
        clip-to-geometry = true;
      };

      layer-rule = [
        {
          match-namespace = "^noctalia-overview.*";
          place-within-backdrop = true;
        }
        {
          match-namespace = "^noctalia-wallpaper.*";
          place-within-backdrop = true;
        }
      ];

      layout = {
        background-color = "transparent";
      };

      overview = {
        workspace-shadow.off = true;
      };

      debug = {
        honor-xdg-activation-with-invalid-serial = true;
      };
    };
  };
}
