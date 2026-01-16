{
  description = "NixOS system with tuigreet, Hyprland, Cosmic, automation and home-manager";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, ... }: let
    system = "x86_64-linux";
    hostname = "HOSTNAME";
    username = "USERNAME";
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };
  };
}
