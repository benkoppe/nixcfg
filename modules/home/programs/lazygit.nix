{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.programs.lazygit.enable = lib.mkEnableOption "lazygit";

  config = lib.mkIf config.myHome.programs.lazygit.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        promptToReturnFromSubprocess = false;
      };
    };
  };
}
