{ lib, ... }:
{
  flake.modules.hjem.gh =
    { pkgs, ... }:
    {
      packages = [
        pkgs.gh
      ];

      xdg.config.files."gh/config.yml" = {
        generator = lib.generators.toYAML { };
        value = {
          version = 1;
        };
      };
    };

  flake.modules.hjem.git =
    { pkgs, ... }:
    {
      packages = [
        pkgs.git-lfs
        pkgs.mergiraf
      ];

      rum.programs.git = {
        enable = true;

        ignore = ''
          *.swp
        '';

        integrations.difftastic = {
          enable = true;
        };

        # mergiraf
        attributes = ''
          * merge=mergiraf
        '';

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

          # use git-lfs
          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };

          # use mergiraf
          merge.mergiraf = {
            name = "mergiraf";
            driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
          };

          # bitwarden signing key
          commit.gpgsign = true;
          gpg.format = "ssh";
          user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6fpMM43mpq3bQajVwztaNe9cIbzy6QYZO5+9t9Wv+n";
        };
      };
    };
}
