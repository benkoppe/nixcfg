{
  config,
  lib,
  pkgs,
  self,
  ...
}:
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
    hostName = "jordan";
    primaryUser = "ben";

    profiles.base.enable = true;

    programs = {
      browsers.enable = true;
      hammerspoon.enable = true;
      karabiner.enable = true;
    };
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users =
    let
      primaryUser = config.myDarwin.primaryUser;
    in
    {
      "${primaryUser}" = {
        name = primaryUser;
        home = "/Users/${primaryUser}";
        isHidden = false;
        shell = pkgs.zsh;
      };
    };
}
