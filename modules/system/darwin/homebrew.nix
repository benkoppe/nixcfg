{ inputs, ... }:
{
  flake.modules.darwin.homebrew =
    { config, ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      homebrew = {
        enable = true;
        global.autoUpdate = false;
        onActivation = {
          upgrade = true;
          cleanup = "zap";
        };
        taps = builtins.attrNames config.nix-homebrew.taps;
      };

      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        mutableTaps = false;
        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
          "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        };

        user = "ben";
      };
    };
}
