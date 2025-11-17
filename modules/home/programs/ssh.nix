{
  config,
  lib,
  pkgs,
  self,
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
            addKeysToAgent = "yes";
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
          matchBlocks =
            let
              inherit (config.mySnippets) hosts;
            in
            {
              "russ" = {
                hostname = hosts.russ.ipv4;
                user = "root";
                identitiesOnly = true;
                identityFile = config.age.secrets.ssh-russ.path;
              };

              "builder-1" = {
                hostname = hosts.builder-1.ipv4;
                user = "builder";
                identitiesOnly = true;
                identityFile = config.age.secrets.ssh-builder-1.path;
              };

              "builder-1-root" = {
                hostname = hosts.builder-1.ipv4;
                user = "root";
                identitiesOnly = true;
                identityFile = config.age.secrets.ssh-builder-1-root.path;
              };

              "*" = {
                host = "*";
                user = "root";
                identitiesOnly = true;
                identityFile = config.age.secrets.ssh-lxc-bootstrap.path;
              };
            };
        };

        age.secrets = {
          ssh-russ = {
            file = "${self.inputs.secrets}/pve/russ-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/russ";
            mode = "600";
          };

          ssh-builder-1 = {
            file = "${self.inputs.secrets}/pve/builder-1-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/builder-1";
            mode = "600";
          };

          ssh-builder-1-root = {
            file = "${self.inputs.secrets}/pve/builder-1-root-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/builder-1-root";
            mode = "600";
          };

          ssh-lxc-bootstrap = {
            file = "${self.inputs.secrets}/pve/lxc-bootstrap-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/lxc-bootstrap";
            mode = "600";
          };
        };
      })
    ]
  );
}
