{ inputs, ... }:
{
  flake.modules.darwin.hjem = {
    imports = [ inputs.hjem.darwinModules.default ];
  };

  flake.modules.nixos.hjem = {
    imports = [ inputs.hjem.nixosModules.default ];
  };
}
