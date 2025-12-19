{
  config,
  lib,
  pkgs,
  self,
  inputs,
  inputs',
  system,
  ...
}:
{
  imports =
    let
      inherit (self) inputs;
    in
    [
      self.snippetsModule
      inputs.determinate.nixosModules.default
      inputs.ragenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
    ];

  options.myNixOS.profiles.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOS.profiles.base.enable {
    myNixOS = {
      programs.nix.enable = true;
    };

    mySnippets = {
      primaryUser = lib.mkDefault "root";
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit
          self
          inputs
          inputs'
          system
          ;
      };
      backupFileExtension = "backup";
    };

    nixpkgs = {
      config.allowUnfree = true;

      hostPlatform = lib.mkDefault system;

      overlays = self.defaultOverlays;
    };

    environment.systemPackages = with pkgs; [
      vim
      git
      nh
    ];

    security.sudo.enable = true;

    users.mutableUsers = lib.mkDefault false;

    time.timeZone = lib.mkDefault "America/Los_Angeles";

    # Cache DNS lookups to improve performance
    services.resolved = {
      extraConfig = ''
        Cache=true
        CacheFromLocalhost=true
      '';
    };

    system.stateVersion = "25.11";
  };
}
