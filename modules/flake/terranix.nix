{ inputs, self, ... }:
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

      terranix.terranixConfigurations =
        lib.genAttrs
          [
            "nix-builder"
            "adguard"
            "lldap"
            "pocket-id"
            "vaultwarden"
            "immich"
            "forgejo"
            "forgejo-runner"
            "garage-dray"
            "komodo"
            "glance"
            "alloy"
            "prometheus"
            "grafana"
            "influxdb"
            "cloudflared-dray"
            "tailscale-dray"
          ]
          (host: {
            workdir = "terraform/${host}";

            extraArgs = { inherit self; };

            modules = [
              ../terranix
              ../../hosts/${host}/terranix.nix
              self.snippetsModule
              {
                mySnippets.hostName = host;
              }
            ];
          });
    };
}
