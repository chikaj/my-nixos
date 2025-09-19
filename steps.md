## BTRFS disk configuration and NixOS system installation

1. Boot the NixOS live USB (minimal ISO).

2. You will immediately have a shell prompt as the nixos user, with full sudo/root privileges (no password required).

3. From the terminal, you can:

  * Use lsblk or fdisk to inspect disk devices.

4. From the terminal, run:

#### Disko Partitioning

  * Run ```git clone https://github.com/chikaj/my-nixos.git```

  * Follow the prompts to partition and encrypt your drive
  * Check the mounted partitions, files and templating for completeness

#### Install NixOS
  * (continued) As prompted, run nixos-install --flake /mnt/etc/nixos#${HOSTNAME}

5. On completion, reboot and remove the USB.
