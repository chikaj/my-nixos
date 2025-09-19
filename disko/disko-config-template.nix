{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mydisk"; # Change this to match your actual disk! Like nvme2n1
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                # Opens with password prompt at boot
                content = {
                  type = "table";
                  layout = [
                    # The first container is for the root system
                    {
                      type = "filesystem";
                      format = "btrfs";
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
                    }
                    # The second container is for swap
                    {
                      type = "swap";
                      size = "128M";        # Should be at least as large as your RAM for hibernation
                      priority = 100;       # Priority can be set as needed
                    }
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
