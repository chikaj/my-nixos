{ ... }:

{
  boot.initrd.systemd.enable = true;

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

  # Hibernation support (disabled for now — needs resume offset calc for Btrfs+LUKS swapfile)
  # `boot.resumeDevice = "/dev/mapper/cryptroot";`
}
