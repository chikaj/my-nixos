{ ... }:

{
  imports = [
    ./01-user.nix
    ./02-hardware.nix
    ./03-services.nix
    ./04-wm.nix
    ./05-boot.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "TIMEZONE";

  system.stateVersion = "25.05";
}
