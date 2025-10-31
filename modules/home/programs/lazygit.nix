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

        git = {
          pagers = [
            {
              # directly reference the binary from the Nix store
              externalDiffCommand = "${pkgs.difftastic}/bin/difft --color=always --display=inline --syntax-highlight=off";
            }
          ];
        };
      };
    };
  };
}
