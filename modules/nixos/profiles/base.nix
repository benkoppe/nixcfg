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
      inputs = self.inputs;
    in
    [
      inputs.determinate.nixosModules.default
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-generators.nixosModules.all-formats
      inputs.disko.nixosModules.disko
    ];

  options.myNixOS.profiles.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOS.profiles.base.enable {
    nix.settings = {
      sandbox = false;
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
        "https://install.determinate.systems"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      ];
      trusted-users = [
        "root"
        "@wheel"
        "builder"
      ];
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit self; };
      backupFileExtension = "backup";
    };

    nixpkgs = {
      config.allowUnfree = true;
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
  };
}
