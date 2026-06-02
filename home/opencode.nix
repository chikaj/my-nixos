{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pkgs.opencode
  ];

  xdg.configFile."opencode/opencode.json".text = ''
    {
      "$schema": "https://opencode.ai/config.json"
    }
  '';

  xdg.configFile."opencode/tui.json".text = ''
    {
      "$schema": "https://opencode.ai/tui.json"
    }
  '';
}
