# To update pgbranch:
#   1. Update `rev` below to the new tag (e.g. v1.0.16)
#   2. Reset `hash` and `vendorHash` to ""
#   3. sudo nixos-rebuild switch --flake /etc/nixos#teewinot
#   4. Copy the real hashes from the error output back in
#   5. sudo nixos-rebuild switch --flake /etc/nixos#teewinot
{ pkgs, lib, ... }:

let
  pgbranch = pkgs.buildGoModule rec {
    pname = "pgbranch";
    version = "v1.0.15";

    src = pkgs.fetchFromGitHub {
      owner = "le-vlad";
      repo = "pgbranch";
      rev = "v1.0.15";
      hash = "sha256-Zo5mCbIEkbnWE773gxZjc9DwS4CzL1WYSumXlYg0E1k=";
    };

    subPackages = [ "cmd/pgbranch" ];

    vendorHash = "sha256-IGkw9Sld5wQeusUbIoQaz8fUmaod1T6tFzqtzN00YT0=";

    ldflags = [ "-s" "-w" ];

    meta = with lib; {
      description = "Git-like branching for PostgreSQL databases";
      homepage = "https://pgbranch.dev";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
in {
  home.packages = [ pgbranch ];
}
