{ config, pkgs, lib, ... }:

let
  superfile-v15 = pkgs.buildGoModule {
    pname = "superfile";
    version = "1.5.0";

    src = pkgs.fetchFromGitHub {
      owner = "yorukot";
      repo = "superfile";
      rev = "v1.5.0";
      hash = "sha256-uzlPc4F9FkuXVmE8zYUPs91f1e6Jje/YayfuzUzsSL8=";
    };

    vendorHash = "";

    nativeBuildInputs = [ pkgs.exiftool ];

    ldflags = [
      "-s"
      "-w"
    ];
  };
in
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

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    enableZshIntegration = true;
    enableNushellIntegration = true;
    extraPackages = with pkgs; [
      ffmpeg
      _7zz
      jq
      poppler
      fd
      ripgrep
      fzf
      zoxide
      resvg
    ];
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
    package = superfile-v15;
    settings = {
      theme = "catppuccin-frappe";
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {};
    initContent = ''
      export EDITOR=hx
    '';
  };
}
