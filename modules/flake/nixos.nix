{
  self,
  inputs,
  ...
}:
{
  flake = {
    diskoConfigurations = {
      simple-ext4 = ../disko/simple-ext4.nix;
    };

    nixosConfigurations = inputs.nixpkgs.lib.genAttrs [ "russ" ] (
      host:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          ../../hosts/${host}
          inputs.determinate.nixosModules.default
          inputs.agenix.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-generators.nixosModules.all-formats
          ../nixos

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit self; };
              backupFileExtension = "backup";
            };

            nixpkgs = {
              config.allowUnfree = true;
            };
          }
        ];

        specialArgs = { inherit self; };
      }
    );
  };
}
