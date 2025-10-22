{
  lib,
  self,
  pkgs,
  ...
}:
{
  options = {
    mySnippets.nix.settings = lib.mkOption {
      type = lib.types.attrs;
      description = "Default nix settings shared across machines.";

      default = lib.mkMerge [
        (
          let
            nixConfig = (import (self + /flake.nix)).nixConfig;
            removed = lib.optionals pkgs.stdenv.isDarwin [ "use-cgroups" ];
          in
          lib.removeAttrs nixConfig removed
        )
        {
          # any additional config here
        }
      ];
    };
  };
}
