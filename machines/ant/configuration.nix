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
    profile-full
  ];

  hjem.users.ben = {
    user = "ben";
    directory = "/Users/ben";
  };

  networking =
    let
      hostName = "ant";
    in
    {
      computerName = hostName;
      localHostName = hostName;

      applicationFirewall.enable = true;
    };

  system.primaryUser = "ben";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.stateVersion = 5;
}
