{
  self,
  inputs,
  lib,
  ...
}:
{
  flake = {
    colmenaHive = inputs.colmena.lib.makeHive (
      {
        meta = {
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            overlays = [ ];
          };
          specialArgs = {
            inherit self;
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
    );
  };
}
