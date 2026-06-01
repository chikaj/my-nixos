{ config, pkgs, inputs, ... }:

{
  programs.niri = {
    package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    settings = {
      spawn-at-startup = [
        {
          argv = [ "noctalia-shell" ];
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
        background-color = "#1e1e2e";
      };

      environment = {
        TERMINAL = "ghostty";
        NIXOS_OZONE_WL = "1";
      };

      binds = {
        "Mod+T".action."spawn-terminal" = {};
        "Mod+Q".action."close-window" = {};
        "Mod+Shift+Q".action.spawn = [ "niri" "msg" "quit" ];
        "Mod+W".action."focus-workspace-down" = {};
        "Mod+E".action."focus-workspace-up" = {};
        "Mod+Shift+W".action."move-window-to-workspace-down" = {};
        "Mod+Shift+E".action."move-window-to-workspace-up" = {};
        "Mod+F".action."toggle-window-floating" = {};
        "Mod+Shift+F".action."toggle-fullscreen" = {};
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
