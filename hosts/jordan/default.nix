{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  computerName = "jordan";
  primaryUser = "ben";
in
{
  imports = [
    ./home.nix
    ./homebrew.nix
    ./dock.nix
  ];

  environment = {
    shells = with pkgs; [
      zsh
    ];
  };

  myDarwin = {
    primaryUser = primaryUser;

    profiles.base.enable = true;

    programs = {
      browsers.enable = true;
      hammerspoon.enable = true;
      karabiner.enable = true;
    };
  };

  networking = {
    computerName = computerName;
    hostName = computerName;
    localHostName = computerName;
  };

  nix-homebrew = {
    enable = true;
    mutableTaps = false;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = self.inputs.homebrew-core;
      "homebrew/homebrew-cask" = self.inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = self.inputs.homebrew-bundle;
      "sst/homebrew-tap" = self.inputs.homebrew-sst-tap;
    };

    user = primaryUser;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users = {
    "${primaryUser}" = {
      name = primaryUser;
      home = "/Users/${primaryUser}";
      isHidden = false;
      shell = pkgs.zsh;
    };
  };
}
