{
  lib,
  config,
  inputs',
  pkgs,
  ...
}:
{
  options.myHome.profiles.workstation.enable = lib.mkEnableOption "workstation home configuration";

  config = lib.mkIf config.myHome.profiles.workstation.enable {
    myHome = {
      profiles.full.enable = true;
      profiles.gaming.enable = true;

      programs = {
        nushell.enable = true;
        helix.enable = false;

        claude-code.enable = true;

        defaultbrowser.enable = true;

        git.signingKey.enable = true;
        git.forgejo.enable = true;

        ssh.enable = true;
        ssh.enableServers = true;
      };
    };

    programs.gh.enable = true;

    home.packages = with pkgs; [
      inputs'.ragenix.packages.ragenix
      inputs'.opencode.packages.default

      nix-tree
    ];
  };
}
