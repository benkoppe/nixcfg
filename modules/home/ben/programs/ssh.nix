{
  flake.modules.nixos."ben_ssh_secrets" =
    { pkgs, ... }:
    {
      clan.core.vars.generators."github-ssh-key" = {
        files."key" = {
          secret = true;
          owner = "ben";
        };
        files."key.pub" = {
          secret = true;
          owner = "ben";
        };
        runtimeInputs = [ pkgs.openssh ];
        script = ''
          ssh-keygen -t ed25519 -N "" -C "" -f "$out"/key
        '';
        share = true;
      };
    };

  flake.modules.homeManager."ben_ssh" =
    { osConfig, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        matchBlocks = {
          "github.com" = {
            identitiesOnly = true;
            identityFile = [
              osConfig.clan.core.vars.generators."github-ssh-key".files."key".path
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
    };
}
