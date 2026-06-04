{ pkgs, ... }:

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
      device = "/swapfile";
      # size = 256 * 1024 * 1024;
    }
  ];

  systemd.services.create-swapfile = let
    b = "${pkgs.bash}/bin/bash";
    util = "${pkgs.util-linux}";
    core = "${pkgs.coreutils}";
    e2fs = "${pkgs.e2fsprogs}";
  in {
    description = "Create swapfile with nocow on Btrfs";
    requiredBy = [ "swap-swapfile.swap" ];
    before = [ "swap-swapfile.swap" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecCondition = "${b} -c '! test -f /swapfile'";
      ExecStart = "${b} -c '${core}/bin/truncate -s 0 /swapfile && ${e2fs}/bin/chattr +C /swapfile && ${util}/bin/fallocate -l 256M /swapfile && ${core}/bin/chmod 0600 /swapfile && ${util}/bin/mkswap /swapfile'";
    };
  };

  # Hibernation support (disabled for now — needs resume offset calc for Btrfs+LUKS swapfile)
  # `boot.resumeDevice = "/dev/mapper/cryptroot";`
}
