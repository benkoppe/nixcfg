{ inputs, self, ... }:
{
  flake.modules.generic.hjem = {
    hjem.extraModules = [ inputs.hjem-rum.hjemModules.hjem-rum ];
  };

  flake.modules.darwin.hjem = {
    imports = [
      inputs.hjem.darwinModules.default
      self.modules.generic.hjem
    ];
  };

  flake.modules.nixos.hjem = {
    imports = [
      inputs.hjem.nixosModules.default
      self.modules.generic.hjem
    ];
  };
}
