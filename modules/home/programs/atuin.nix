{ lib, config, ... }:
{
  options.myHome.programs.atuin.enable = lib.mkEnableOption "atuin shell history manager";

  config = lib.mkIf config.myHome.programs.atuin.enable (
    lib.mkMerge [
      {
        programs.atuin = {
          enable = true;

          flags = [ "--disable-up-arrow" ];

          settings = {
            style = "auto";
            keymap_mode = "vim-insert";
          };
        };
      }

      (lib.mkIf config.myHome.programs.zsh.enable {
        programs.atuin.enableZshIntegration = true;
      })

      (lib.mkIf config.myHome.programs.nushell.enable {
        programs.atuin.enableNushellIntegration = true;
      })
    ]
  );
}
