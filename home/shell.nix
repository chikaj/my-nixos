{ config, pkgs, lib, ... }:

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
      $env.config = {
        show_banner: false
        buffer_editor = "zed"
        hooks = {
          pre_prompt = [
            { tput cup (term size).rows 0 }
          ]
        }
      }

      def --env spf [...args] {
        let state_home = ($env.XDG_STATE_HOME? | default $"($env.HOME)/.local/state")
        $env.SPF_LAST_DIR = $"($state_home)/superfile/lastdir"
        ^superfile ...$args
        if ($env.SPF_LAST_DIR? | is-not-empty) and ($env.SPF_LAST_DIR | path exists) {
          let content = (open $env.SPF_LAST_DIR)
          let path = ($content
            | str replace 'cd ' ''
            | str trim
            | str replace --all "'" ''
            | str replace --all '"' ''
            | str trim)
          cd $path
        }
      }

      mkdir ~/.cache/devenv
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

  programs.zsh = {
    enable = true;
    shellAliases = {};
    initContent = ''
      export EDITOR=hx
      eval "$(devenv hook zsh)"

      spf() {
        local f="''${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
        superfile "$@"
        [[ -f "$f" ]] && cd "$(sed "s/^cd //; s/['\"]//g" "$f")"
      }
    '';
  };

  # Pre-create the devenv hook cache so nushell's `source` doesn't fail on first login
  # when no devenv project has been entered yet.  After entering a devenv project,
  # `devenv hook nu | save --force` will overwrite it with real content.
  home.activation.ensureDevenvHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.cache/devenv"
    touch "$HOME/.cache/devenv/hook.nu"
  '';
}
