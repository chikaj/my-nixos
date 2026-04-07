{ ... }:

{
  # Memory optimization: ZRAM and swappiness
  services.zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Unlock LUKS early for initramfs
  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/mapper/cryptroot";
      preLVM = true;
    };
  };

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
