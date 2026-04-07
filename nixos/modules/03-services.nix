{ config, pkgs, ... }:

{
  xdg.portal.enable = true;
  xdg.portal.wl-roots.enable = true;
  xdg.portal.config.common.default = [ "*" ];

  # Required services for Noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Tuigreet + greetd setup for session selection
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --sessions /run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions";
        user = "greeter";
      };
    };
  };
}
