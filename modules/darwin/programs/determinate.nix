{ config, lib, ... }:
{
  options.myDarwin.programs.determinate.enable =
    lib.mkEnableOption "sane determinate-nix configuration";

  config = lib.mkIf config.myDarwin.programs.determinate.enable {
    nix = {
      enable = false;

      # package = pkgs.nix;

      settings = {
        trusted-users = [
          "@admin"
          "${config.myDarwin.primaryUser}"
        ];
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      };

      # gc = {
      # automatic = true;
      # interval = { Weekday = 0; Hour = 2; Minute = 0; };
      # options = "--delete-older-than 30d";
      # };

      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    determinate-nix.customSettings = {
      trusted-users = [
        "@admin"
        "${config.myDarwin.primaryUser}"
      ];
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
    };
  };
}
