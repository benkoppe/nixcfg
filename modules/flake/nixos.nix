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
      (lib.genAttrs [ "russ" ] (
        host:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.default
            ../../hosts/${host}
          ];

          specialArgs = { inherit self; };
        }
      ))
      // (lib.genAttrs [ "builder-1" ] (
        microhost:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.default
            ../../hosts/microhosts/${microhost}.nix
          ];

          specialArgs = { inherit self; };
        }
      ));
  };
}
