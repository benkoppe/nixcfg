{
  self,
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake = {
    colmenaHive = withSystem "x86_64-linux" (
      ctx:
      inputs.colmena.lib.makeHive (
        {
          meta = {
            nixpkgs = import inputs.nixpkgs {
              inherit (ctx) system;
              overlays = [ ];
            };
            specialArgs = {
              inherit self inputs;
              inherit (ctx) inputs' system;
            };
          };
        }
        // (lib.genAttrs
          [
            "russ"
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
            "influxdb"
          ]
          (
            host:
            { config, ... }:
            {
              deployment =
                let
                  cfg = config.mySnippets.hosts.${host};
                in
                {
                  targetHost = cfg.targetHost or cfg.ipv4;
                  targetUser = "root";
                };
              imports = [
                ../../hosts/${host}
                ../nixos
                {
                  mySnippets.hostName = host;
                }
              ];
            }
          )
        )
      )
    );
  };
}
