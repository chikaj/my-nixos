{ ... }:

{
  imports = [
    ./modules/00-default.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "HOSTNAME";
}
