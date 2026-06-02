{ ... }:

{
  boot.initrd.systemd.enable = true;

  # Force console to physical display (fixes invisible LUKS prompt on NVIDIA)
  boot.kernelParams = [ "console=tty0" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

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
