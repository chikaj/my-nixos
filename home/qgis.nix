{ pkgs, ... }:

{
  home.packages = [
    (pkgs.qgis.override {
      withGrass = true;
      withServer = true;
    })
  ];
}
