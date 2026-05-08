{ inputs, ... }:
{
  flake.modules.darwin.homebrew = {
    imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        upgrade = true;
        cleanup = "zap";
      };
    };

    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      mutableTaps = false;
      autoMigrate = true;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
        "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      };

      user = "ben";
    };
  };
}
