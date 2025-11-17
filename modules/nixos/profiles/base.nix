{
  config,
  lib,
  pkgs,
  self,
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
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-generators.nixosModules.all-formats
      inputs.disko.nixosModules.disko
    ];

  options.myNixOS.profiles.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOS.profiles.base.enable {
    myNixOS = {
      programs.nix.enable = true;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit self; };
      backupFileExtension = "backup";
    };

    nixpkgs = {
      config.allowUnfree = true;

      hostPlatform = lib.mkDefault "x86_64-linux";
    };

    environment.systemPackages = with pkgs; [
      vim
      git
      nh
    ];

    security.sudo.enable = true;

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
