{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.programs.ssh = {
    enable = lib.mkEnableOption "openssh client";

    enableServers = lib.mkEnableOption "reach main servers via ssh";
  };

  config = lib.mkIf config.myHome.programs.ssh.enable (
    lib.mkMerge [
      {
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

          # equivalent to enableDefaultConfig = true;
          matchBlocks."*" = {
            forwardAgent = false;
            addKeysToAgent = "no";
            compression = false;
            serverAliveInterval = 0;
            serverAliveCountMax = 3;
            hashKnownHosts = false;
            userKnownHostsFile = "~/.ssh/known_hosts";
            controlMaster = "no";
            controlPath = "~/.ssh/master-%r@%n:%p";
            controlPersist = "no";
          };
        };
      }

      (lib.mkIf config.myHome.programs.ssh.enableServers {
        programs.ssh = {
        };
      })
    ]
  );
}
