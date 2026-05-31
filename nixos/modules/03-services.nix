{ config, pkgs, ... }:

{
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = [ "*" ];

  # Required services for Noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Tuigreet + greetd setup
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --cmd ${config.programs.niri.package}/bin/niri-session
        '';
        user = "greeter";
      };
    };
  };
}
