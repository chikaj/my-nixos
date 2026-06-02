{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "opencode";
  version = "1.15.13";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    hash = "sha256-UXhaB8AJ8nxRJaUjXFoP94Qz2s4H9z+8ROtnLq1LPXk=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    install -m755 -D opencode $out/bin/opencode
  '';

  meta = with lib; {
    description = "AI coding agent built for the terminal";
    homepage = "https://opencode.ai";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
}
