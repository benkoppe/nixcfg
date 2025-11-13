{ inputs, ... }:
{
  perSystem =
    {
      system,
      lib,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
      };

      terranix.terranixConfigurations = lib.genAttrs [ "adguard" ] (host: {
        workdir = "terraform/${host}";

        modules = [
          ../terranix
          ../../hosts/${host}/terranix.nix
          {
            myTerranix.hostName = host;
          }
        ];
      });
    };
}
