{ lib, config, ... }:
{
  options.myHome.programs.yazi.enable = lib.mkEnableOption "yazi terminal file explorer";

  config = lib.mkIf config.myHome.programs.yazi.enable (
    lib.mkMerge [
      {
        programs.yazi = {
          enable = true;

          shellWrapperName = "y";
          enableBashIntegration = true;
        };
      }

      (lib.mkIf config.myHome.programs.zsh.enable {
        programs.yazi.enableZshIntegration = true;
      })

      (lib.mkIf config.myHome.programs.nushell.enable {
        programs.yazi.enableNushellIntegration = true;
      })
    ]
  );
}
