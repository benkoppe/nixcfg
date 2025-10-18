{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myNixOS.profiles.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOS.profiles.base.enable {
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
