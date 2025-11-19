{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.profiles.gaming.enable = lib.mkEnableOption "gaming home configuration";

  config = lib.mkIf config.myHome.profiles.gaming.enable {
    myHome = {
      profiles.base.enable = true;
    };

    home.packages = with pkgs; [
      prismlauncher
    ];
  };
}
