{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.programs.ssh.enable = lib.mkEnableOption "openssh client";

  config = lib.mkIf config.myHome.programs.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      package = pkgs.openssh;

      matchBlocks = {
        "github.com" = {
          identitiesOnly = true;
          identityFile = [
            "~/.ssh/id_github"
          ];
        };
      };
    };
  };
}
