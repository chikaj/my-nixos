{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mydisk"; # Change this to match your actual disk! Like nvme2n1
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                label = "ESP";
                mountpoint = "/boot";
              };
            };
            # LUKS partition with Btrfs subvolumes
            luks = {
              size = "100%";
              label = "cryptroot";
              content = {
                type = "luks";
                name = "cryptroot";
                # Opens with password prompt at boot
                content = {
                  type = "btrfs";
                  subvolumes = {
                    root = { mountpoint = "/"; };
                    nix = { mountpoint = "/nix"; };
                    home = { mountpoint = "/home"; };
                    persist = { mountpoint = "/persist"; }; # optional
                    log = { mountpoint = "/var/log"; };    # optional
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
