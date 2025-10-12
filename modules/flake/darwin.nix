{
  self,
  inputs,
  ...
}:
{
  flake = {
    darwinModules.default = ../darwin;

    darwinConfigurations.jordan = inputs.nix-darwin.lib.darwinSystem {
      modules = [
        ../../hosts/jordan
        self.darwinModules.default
        inputs.agenix.darwinModules.default
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.determinate.darwinModules.default

        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = false;
            extraSpecialArgs = { inherit self; };
            backupFileExtension = "backup";
          };

          nixpkgs = {
            hostPlatform = "aarch64-darwin";
            config.allowUnfree = true;
          };
        }
      ];

      specialArgs = { inherit self; };
    };
  };
}
