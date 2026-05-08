{ self, ... }:
{
  imports = with self.modules.darwin; [
    basics
    homebrew
    karabiner

    macos-defaults

    hjem
  ];

  hjem.extraModules = with self.modules.hjem; [
    ghostty
  ];

  hjem.users.ben = {
    user = "ben";
    directory = "/Users/ben";
  };

  system.primaryUser = "ben";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 5;
}
