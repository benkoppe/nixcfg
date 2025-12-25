{
  flake.terranixLib.mkTerranixConfig =
    { modules, pkgs }:
    {
      inherit modules;

      terraformWrapper.package = pkgs.opentofu;
    };
}
