{
  self,
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake = {
    nixosModules = {
      default = ../nixos;
    };

    nixosConfigurations = lib.genAttrs [ ] (
      host:
      withSystem "x86_64-linux" (
        ctx:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.default
            ../../hosts/${host}
            {
              mySnippets.hostName = host;
            }
          ];

          specialArgs = {
            inherit self inputs;
            inherit (ctx) inputs' system;
          };
        }
      )
    );
  };
}
