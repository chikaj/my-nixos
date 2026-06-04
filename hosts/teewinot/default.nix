# Per-machine system config (hostname, timezone, user, filesystems, imports).
# Shared system config lives in ../../modules/, user config in ../../home/.
# Packages unique to this machine go in ./machine-specific.nix.
{ lib, pkgs, ... }:

{
  networking.hostName = "teewinot";
  time.timeZone = "America/Chicago";

  users.users.chikaj = {
    isNormalUser = true;
    description = "Desktop Wizard";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.nushell;
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPz0V4d63WCaYvbTwfCg+S9v6vv1M7YYRjNk9GONPhM ncurrit@gmail.com" ];
  };

  home-manager.users.chikaj = import ../../home;

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/9718a794-ad1f-46bd-8b8d-6b53fde378d9";
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };
    "/home" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" "noatime" ];
    };
    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=persist" "compress=zstd" "noatime" ];
    };
    "/var/log" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime" ];
    };
    "/boot" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=boot" "compress=zstd" "noatime" ];
    };
    "/efi" = {
      device = "/dev/disk/by-uuid/7C29-491E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  imports = [
    ../../modules/00-default.nix
    ../../modules/02-hardware.nix
    ../../modules/03-services.nix
    ../../modules/04-wm.nix
    ../../modules/05-boot.nix
    ../../modules/06-containers.nix
    ./hardware.nix
    ./machine-specific.nix
  ];
}
