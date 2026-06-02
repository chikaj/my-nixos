{ pkgs, ... }:

{
  home.packages = with pkgs; [
    flameshot
  ];

  xdg.configFile."flameshot/flameshot.ini" = {
    force = true;
    text = ''
      [General]
      useGrimAdapter=true
    '';
  };
}
