{ config, pkgs, ... }:

{
  users.users.USERNAME = {
    isNormalUser = true;
    description = "Desktop Wizard";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.nushell;
    initialPassword = "PASSWORD";
  };
}
