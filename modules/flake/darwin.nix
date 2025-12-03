{
  self,
  inputs,
  withSystem,
  ...
}:
{
  flake = {
    darwinModules = {
      default = ../darwin;
    };

    darwinConfigurations.jordan = withSystem "aarch64-darwin" (
      ctx:
      inputs.nix-darwin.lib.darwinSystem {
        modules = [
          self.darwinModules.default
          ../../hosts/jordan
        ];

        specialArgs = {
          inherit self inputs;
          inherit (ctx) inputs' system;
        };
      }
    );
  };
}
