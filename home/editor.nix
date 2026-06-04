{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        line-number = "relative";
      };
    };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "zed" "exec ${pkgs.zed-editor}/bin/zed \"$@\"")
  ];

  programs.zed-editor = {
    enable = true;
    userSettings = {
      buffer_font_family = "CaskaydiaCove Nerd Font";
      buffer_font_size = 15;
      language_models = {
        openai = {
          version = "1";
          api_url = "https://rustcoder.gaia.domains/v1";
        };
      };
      assistant = {
        provider = "openai";
        default_model = {
          provider = "openai";
          model = "rustcoder";
        };
      };
    };
  };
}
