{ lib, ... }:
{
  flake.modules.nixos."ben_git_secrets" = {
    clan.core.vars.generators."github-signing-key" = {
      files."key" = {
        secret = true;
        owner = "ben";
      };
      files."key.pub" = {
        secret = true;
        owner = "ben";
      };
      script = ''
        ssh-keygen -t ed25519 -N "" -C "" -f "$out"/key
      '';
      share = true;
    };

    clan.core.vars.generators."forgejo-ssh-key" = {
      files."key" = {
        secret = true;
        owner = "ben";
      };
      files."key.pub" = {
        secret = true;
        owner = "ben";
      };
      script = ''
        ssh-keygen -t ed25519 -N "" -C "" -f "$out"/key
      '';
      share = true;
    };
  };

  flake.modules.homeManager."ben_git" =
    { config, osConfig, ... }:
    {
      options.my.home.git = {
        signingKey.enable = lib.mkEnableOption "use github signing key for commits";
        forgejo.enable = lib.mkEnableOption "configure git for forgejo usage";
      };

      config = lib.mkMerge [
        {
          programs.difftastic = {
            enable = true;
            git.enable = true;
            git.diffToolMode = true;
          };

          programs.mergiraf.enable = true;

          programs.git = {
            enable = true;
            ignores = [ "*.swp" ];
            lfs.enable = true;

            settings = {
              user = {
                name = "ben";
                email = "koppe.development@gmail.com";
              };
              init.defaultBranch = "main";
              core = {
                editor = "vim";
                autocrlf = "input";
              };
              pull.rebase = true;
              push.autoSetupRemote = true;

              rebase = {
                autoStash = true;
                autoSquash = true;
                updateRefs = true;
              };
              rerere.enabled = true;

              fetch.fsckObjects = true;
              receive.fsckObjects = true;
              transfer.fsckobjects = true;

              # url."ssh://git@github.com/".insteadOf = "https://github.com/";
            };
          };
        }

        (lib.mkIf config.my.home.git.signingKey.enable (
          let
            githubPublicSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqe4FEfKED0fJ1IETiws0aYV1lzDTBuGJfBFi+WTsJ8 ben@Bens-MBP";
          in
          {
            programs.git.settings = {
              commit.gpgsign = true;
              gpg.format = "ssh";
              user.signingKey = osConfig.clan.core.vars.generators."github-signing-key".files."key".path;
            };

          }
        ))

        (lib.mkIf config.my.home.git.forgejo.enable (
          let
            sshKeyPath = osConfig.clan.core.vars.generators."forgejo-ssh-key".files."key".path;
          in
          {
            programs.git = {
              # settings = {
              #   url."ssh://forgejo@${config.mySnippets.hosts.forgejo.ipv4}/".insteadOf =
              #     "https://git.thekoppe.com/";
              # };

              includes = [
                {
                  condition = "hasconfig:remote.*.url:https://git.thekoppe.com/**";
                  contents = {
                    user = {
                      name = "ben";
                      email = "benjamin.e.koppe@gmail.com";
                    };

                    commit.gpgsign = true;
                    gpg.format = "ssh";
                    user.signingKey = sshKeyPath;

                    core.sshCommand = "ssh -i ${sshKeyPath}";
                  };
                }
              ];
            };

          }
        ))
      ];
    };
}
