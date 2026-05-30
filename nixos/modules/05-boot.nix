{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Memory optimization: ZRAM and swappiness
  zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Swap file inside encrypted root
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 256 * 1024 * 1024;
    }
  ];

  # Hibernation support
  boot.kernelParams = [ "resume=/swap/swapfile" ];
}
