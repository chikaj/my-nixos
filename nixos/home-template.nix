{ ... }:

{
  imports = [
    ./home/default.nix
  ];

  home.username = "USERNAME";
  home.homeDirectory = "/home/USERNAME";
}
