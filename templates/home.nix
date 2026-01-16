{ config, pkgs, ... }:

{
  # Enable home-manager itself
  programs.home-manager.enable = true;

  # Set your username and home directory (replace with your actual values if not using flake modules)
  # home.username = "USERNAME";
  # home.homeDirectory = "/home/USERNAME";

  # State version (update if needed)
  home.stateVersion = "25.05";

  # Enable Fontconfig for graphical fonts support
   fonts.fontconfig.enable = true;

   # Install user packages (Ghostty, starship, Nushell, and nerd-fonts.
    home.packages = with pkgs; [
      ghostty
      helix
      nushell
      starship
      superfile
      zed-editor

      # Install all Nerd Fonts (very large!):
      # nerd-fonts.
      # Or install specific Nerd Fonts:
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.meslo
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      # Add more as desired, e.g. nerd-fonts.hack, nerd-fonts.roboto, etc.
    ];

  # Install Ghostty terminal and configure it
  programs.ghostty = {
    enable = true;
    settings = {
      "background-opacity" = "0.85";
      "gtk-titlebar" = "false";
      "font-family" = "CaskaydiaCove Nerd Font";
      "font-size" = "14";
      "window-decoration" = "false";
      # Add more key/value pairs as needed
    };
  };

  # Install and configure Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$all";
      # Additional Starship config options can go here
    };
  };

  # Helix editor config
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        line-number = "relative";
      };
      # Add more settings as desired
    };
  };

  # Install and set up Nushell
  programs.nushell = {
    enable = true;
    configFile.text = ''
      # Basic Nushell config
      $env.PROMPT_COMMAND = {|| starship_prompt }
      $env.config.buffer_editor = "hx"
      # Add more custom config as needed
    '';
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      # Useful aliases here
    };
    initExtra = ''
      export EDITOR=hx
    '';
  };

  programs.superfile = {
    enable = true;
    settings = {
      theme = "catppuccin-frappe"; # Replace with desired flavor/accent, e.g. "catppuccin-frappe-lavender"
      # More superfile settings...
    };
  };

  programs.zed-editor = {
    enable = true;
    userSettings = {
      buffer_font_family = "CaskaydiaCove Nerd Font";
      buffer_font_size = 15;
      # Gaia AI integration!
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
      # Add other settings as needed, like theme, keymaps, etc.
    };
  };
}
