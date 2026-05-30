{
  description = "NixOS system with Niri, Noctalia, and home-manager";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niri.cachix.org-1:EjH3R0Yj5t5pJbM1rWvQ3L8xK9yC4h7fA6eB2sD5gU0="
    ];
  };
  outputs = inputs@{ self, nixpkgs, home-manager, niri-flake, noctalia, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          niri-flake.nixosModules.niri
          home-manager.nixosModules.home-manager
          {
            home-manager.users.USERNAME = ./home.nix;
          }
        ];
      };
    };
}
