{ config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      "background-opacity" = "0.85";
      "gtk-titlebar" = "false";
      "font-family" = "CaskaydiaCove Nerd Font";
      "font-size" = "14";
      "window-decoration" = "false";
    };
  };

  programs.nushell = {
    enable = true;
    configFile.text = ''
      $env.PROMPT_COMMAND = {|| starship_prompt }
      $env.config.buffer_editor = "hx"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$all";
    };
  };

  programs.superfile = {
    enable = true;
    settings = {
      theme = "catppuccin-frappe";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {};
    initExtra = ''
      export EDITOR=hx
    '';
  };
}
