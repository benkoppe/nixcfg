{ self, pkgs, ... }:
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

  environment.systemPackages = with pkgs; [
    alt-tab-macos
  ];

  hjem.users.ben = {
    user = "ben";
    directory = "/Users/ben";

    imports = with self.modules.hjem; [
      profile-full

      colima
    ];
  };

  determinateNix.customSettings.trusted-users = [
    "root"
  ];

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
