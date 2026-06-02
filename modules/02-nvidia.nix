{ config, pkgs, ... }:

{
  hardware.nvidia = {
    enable = true;
    modesetting.enable = true;
    open = false;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
