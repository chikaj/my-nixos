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
      devenv hook nu | save --force ~/.cache/devenv/hook.nu
      source ~/.cache/devenv/hook.nu
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
    package = pkgs.superfile;
    settings = {
      theme = "catppuccin-frappe";
    };
  };

  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "spf" ''
      exec ${pkgs.superfile}/bin/superfile "$@"
    '')
  ];

  programs.zsh = {
    enable = true;
    shellAliases = {};
    initContent = ''
      export EDITOR=hx
      eval "$(devenv hook zsh)"
    '';
  };
}
