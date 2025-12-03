{
  config,
  lib,
  pkgs,
  inputs,
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

              "nix-builder" = {
                hostname = hosts.nix-builder.ipv4;
                user = "builder";
                identitiesOnly = true;
                identityFile = config.age.secrets.ssh-nix-builder.path;
              };

              "nix-builder-root" = {
                hostname = hosts.nix-builder.ipv4;
                user = "root";
                identitiesOnly = true;
                identityFile = config.age.secrets.ssh-nix-builder-root.path;
              };

              "*" = {
                host = "*";
                user = "root";
                identitiesOnly = true;
                identityFile = [
                  config.age.secrets.ssh-colmena.path
                  config.age.secrets.ssh-lxc-bootstrap.path
                ];
              };
            };
        };

        age.secrets = {
          ssh-russ = {
            file = "${inputs.secrets}/pve/russ-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/russ";
            mode = "600";
          };

          ssh-nix-builder = {
            file = "${inputs.secrets}/pve/nix-builder-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/nix-builder";
            mode = "600";
          };

          ssh-nix-builder-root = {
            file = "${inputs.secrets}/pve/nix-builder-root-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/nix-builder-root";
            mode = "600";
          };

          ssh-lxc-bootstrap = {
            file = "${inputs.secrets}/pve/lxc-bootstrap-key.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/lxc-bootstrap";
            mode = "600";
          };

          ssh-colmena = {
            file = "${inputs.secrets}/pve/colmena.age";
            symlink = false;
            path = "${config.home.homeDirectory}/.ssh/pve/colmena";
            mode = "600";
          };
        };
      })
    ]
  );
}
