{
  config,
  lib,
  ...
}:
{
  options.myHome.programs.nushell.enable = lib.mkEnableOption "nu shell";

  config = lib.mkIf config.myHome.programs.nushell.enable {
    programs.nushell = {
      enable = true;

      settings = {
        show_banner = false;
      };
    };

    programs.starship = {
      enable = true;

      enableNushellIntegration = true;
    };
  };
}
