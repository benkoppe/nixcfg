{ self, ... }:
{
  flake.terranixLib.mkTerranixConfig =
    {
      key,
      modules,
      pkgs,
    }:
    {
      modules =
        let
          defaultModules = with self.modules.terranix; [
            options
            { my.key = key; }
          ];
        in
        modules ++ defaultModules;

      workdir = "terraform/${key}";

      terraformWrapper.package = pkgs.opentofu;
    };
}
