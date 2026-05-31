{ lib, ... }:

{
  imports = [
    ./modules/00-default.nix
    ./hardware-configuration.nix
  ] ++ lib.optionals (builtins.pathExists ./modules/02-nvidia.nix) [
    ./modules/02-nvidia.nix
  ];

  networking.hostName = "HOSTNAME";

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
      device = "/dev/disk/by-uuid/BOOTUUID";
      fsType = "vfat";
    };
  };
}
