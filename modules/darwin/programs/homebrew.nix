{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.programs.homebrew.enable =
    lib.mkEnableOption "strict determinate homebrew configuration";

  config = lib.mkIf config.myDarwin.programs.homebrew.enable {
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
        "homebrew/homebrew-core" = self.inputs.homebrew-core;
        "homebrew/homebrew-cask" = self.inputs.homebrew-cask;
        "homebrew/homebrew-bundle" = self.inputs.homebrew-bundle;
        "sst/homebrew-tap" = self.inputs.homebrew-sst-tap;
      };

      user = config.mySnippets.primaryUser;
    };

  };
}
