# Packages here are installed ONLY on this machine.
# Shared packages are in ../../home/packages.nix or any ../../home/*.nix.
{ config, pkgs, lib, ... }:

{
  home-manager.users.chikaj.home.packages = with pkgs; [
    # machine-specific packages go here
  ];

  # Disable shared features that this machine doesn't need:
  # hardware.bluetooth.enable = lib.mkForce false;
  # services.blueman.enable = lib.mkForce false;
}
