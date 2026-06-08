# To update pgroll:
#   1. Update `version` below to the new tag (e.g. 0.17.0)
#   2. Reset `hash` and `vendorHash` to ""
#   3. sudo nixos-rebuild switch --flake /etc/nixos#teewinot
#   4. Copy the real hashes from the error output back in
#   5. sudo nixos-rebuild switch --flake /etc/nixos#teewinot
{ pkgs, lib, ... }:

let
  pgroll = pkgs.pgroll.overrideAttrs (old: {
    version = "0.16.2";

    src = pkgs.fetchFromGitHub {
      owner = "xataio";
      repo = "pgroll";
      rev = "v0.16.2";
      hash = "sha256-pvc+hKWUY8OPKMU4QNwuTlw8ewhiDrFcS1q/hcOzqSk=";
    };

    vendorHash = "sha256-/oEZbST2Q2HG+qu8nH+mdk/U58aTMznndDHDbFg8fCk=";

    ldflags = [
      "-s" "-w"
      "-X github.com/xataio/pgroll/cmd.Version=0.16.2"
    ];
  });
in {
  home.packages = [ pgroll ];
}
