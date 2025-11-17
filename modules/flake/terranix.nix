{ inputs, self, ... }:
{
  perSystem =
    {
      system,
      lib,
      config,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
      };

      terranix.terranixConfigurations = lib.genAttrs [ "adguard" ] (host: {
        workdir = "terraform/${host}";

        extraArgs = { inherit self; };

        modules = [
          ../terranix
          ../../hosts/${host}/terranix.nix
          self.snippetsModule
          {
            myTerranix.hostName = host;
          }
        ];
      });
    };
}
