{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    vivaldi-widevine
  ];

  xdg.mime.defaults = {
    "text/html" = "vivaldi.desktop";
    "x-scheme-handler/http" = "vivaldi.desktop";
    "x-scheme-handler/https" = "vivaldi.desktop";
    "x-scheme-handler/about" = "vivaldi.desktop";
    "x-scheme-handler/unknown" = "vivaldi.desktop";
    "application/pdf" = "vivaldi.desktop";
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
