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

    nixosConfigurations = lib.genAttrs [ "russ" "builder-1" "adguard" "lxc-bootstrap" ] (
      host:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.default
          ../../hosts/${host}
        ];

        specialArgs = { inherit self; };
      }
    );
  };
}
