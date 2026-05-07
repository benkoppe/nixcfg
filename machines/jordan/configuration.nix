{ self, ... }:
{
  imports = with self.modules.darwin; [
    basics
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 5;
}
