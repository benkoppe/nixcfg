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

    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.11"; # Did you read the comment?
  };
}
