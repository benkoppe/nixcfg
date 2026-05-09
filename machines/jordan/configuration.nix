{ self, ... }:
{
  imports = with self.modules.darwin; [
    basics
    homebrew

    karabiner
    hammerspoon
    browsers

    macos-defaults

    hjem

    ./apps.nix
  ];

  hjem.extraModules = with self.modules.hjem; [
    ghostty

    zsh
    direnv
    atuin

    git
    gh
    lazygit

    nvim
  ];

  hjem.users.ben = {
    user = "ben";
    directory = "/Users/ben";
  };

  system.primaryUser = "ben";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 5;
}
