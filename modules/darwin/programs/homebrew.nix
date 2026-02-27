{
  config,
  lib,
  inputs,
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
      caskArgs = {
        appdir = "/Volumes/T7 Apps/Homebrew";
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

      user = config.mySnippets.primaryUser;
    };

  };
}
