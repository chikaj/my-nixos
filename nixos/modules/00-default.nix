{ ... }:

{
  imports = [
    ./01-user.nix
    ./02-hardware.nix
    ./03-services.nix
    ./04-wm.nix
    ./05-boot.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-substituters = [
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
    ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niri.cachix.org-1:EjH3R0Yj5t5pJbM1rWvQ3L8xK9yC4h7fA6eB2sD5gU0="
    ];
  };

  time.timeZone = "TIMEZONE";

  system.stateVersion = "26.05";
}
