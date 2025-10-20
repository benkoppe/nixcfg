{
  self,
  inputs,
  ...
}:
{
  flake = {
    darwinConfigurations.jordan = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        ../../hosts/jordan
        ../darwin
      ];

      specialArgs = { inherit self; };
    };
  };
}
