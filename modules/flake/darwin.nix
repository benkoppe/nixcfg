{
  self,
  inputs,
  ...
}:
{
  flake = {
    darwinModules = {
      default = ../darwin;
    };

    darwinConfigurations.jordan = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        self.darwinModules.default
        ../../hosts/jordan
      ];

      specialArgs = { inherit self; };
    };
  };
}
