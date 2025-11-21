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
      // (lib.genAttrs [ "russ" "nix-builder" "adguard" ] (
        host:
        { config, ... }:
        {
          deployment = {
            targetHost = config.mySnippets.hosts.${host}.ipv4;
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
      ))
    );
  };
}
