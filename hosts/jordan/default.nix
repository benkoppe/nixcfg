{
  config,
  pkgs,
  ...
}:
let
  inherit (config.mySnippets) primaryUser primaryHome;
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

  mySnippets = {
    hostName = "jordan";
    primaryUser = "ben";
  };

  myDarwin = {
    profiles.base.enable = true;

    programs = {
      browsers.enable = true;
      hammerspoon.enable = true;
      karabiner.enable = true;
      xcode.enable = true;
    };
  };

  users.users = {
    "${primaryUser}" = {
      name = primaryUser;
      home = primaryHome;
      isHidden = false;
      shell = pkgs.zsh;
    };
  };

  age.identityPaths = [ "${primaryHome}/.ssh/id_ed25519" ];
}
