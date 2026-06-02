{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vivaldi
    vivaldi-ffmpeg-codecs
  ];

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "vivaldi.desktop";
    "x-scheme-handler/http" = "vivaldi.desktop";
    "x-scheme-handler/https" = "vivaldi.desktop";
    "x-scheme-handler/about" = "vivaldi.desktop";
    "x-scheme-handler/unknown" = "vivaldi.desktop";
    "application/pdf" = "vivaldi.desktop";
  };
}
