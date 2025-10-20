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
