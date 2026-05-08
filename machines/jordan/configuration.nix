{ self, ... }:
{
  imports = with self.modules.darwin; [
    basics
    homebrew
    karabiner
  ];

  system.primaryUser = "ben";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 5;
}
