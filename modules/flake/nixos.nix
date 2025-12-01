{
  self,
  inputs,
  lib,
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
        ]
        (
          host:
          inputs.nixpkgs.lib.nixosSystem {
            modules = [
              self.nixosModules.default
              ../../hosts/${host}
              {
                mySnippets.hostName = host;
              }
            ];

            specialArgs = { inherit self; };
          }
        );
  };
}
