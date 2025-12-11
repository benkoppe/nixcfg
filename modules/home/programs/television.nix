{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.myHome.programs.television.enable = lib.mkEnableOption "television search tool";

  config = lib.mkIf config.myHome.programs.television.enable (
    lib.mkMerge [
      {
        programs.television = {
          enable = true;

          # enableBashIntegration = true;
        };

        home.packages = with pkgs; [ sesh ];
      }

      (lib.mkIf config.myHome.programs.zsh.enable {
        # programs.television.enableZshIntegration = true;
      })
    ]
  );
}
