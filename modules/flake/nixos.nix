{
  self,
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake = {
    diskoConfigurations = {
      simple-ext4 = ../disko/simple-ext4.nix;
    };

    nixosModules = {
      default = ../nixos;
    };

    nixosConfigurations =
      lib.genAttrs
        [
          "russ"
          "nix-builder"
          "adguard"
          "lxc-bootstrap"
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
        ]
        (
          host:
          withSystem "x86_64-linux" (
            ctx:
            inputs.nixpkgs.lib.nixosSystem {
              modules = [
                self.nixosModules.default
                ../../hosts/${host}
                {
                  mySnippets.hostName = host;
                }
              ];

              specialArgs = {
                inherit self inputs;
                inherit (ctx) inputs' system;
              };
            }
          )
        );
  };
}
