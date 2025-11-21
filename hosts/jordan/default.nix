{
  config,
  pkgs,
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

  users.users =
    let
      inherit (config.mySnippets) primaryUser;
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
