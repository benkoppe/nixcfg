{ self, ... }:
{
  flake.terranixLib.mkTerranixConfig =
    {
      key,
      modules,
      pkgs,
      inputs',
      ...
    }:
    {
      modules =
        let
          defaultModules = with self.modules.terranix; [
            options
            { my.key = key; }
            encryption
          ];
        in
        modules ++ defaultModules;

      workdir = "terraform/${key}";

      terraformWrapper = {
        package = pkgs.opentofu;
        extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
        prefixText = ''
          TF_VAR_passphrase=$(clan secrets get terraform-passphrase)
          export TF_VAR_passphrase
        '';
      };
    };
}
