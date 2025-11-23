{
  config,
  lib,
  self,
  ...
}:
{
  options.myHome.programs.git = {
    enable = lib.mkEnableOption "git";
    signingKey.enable = lib.mkEnableOption "use github signing key for commits";
    forgejo.enable = lib.mkEnableOption "configure git for forgejo usage";
  };

  config = lib.mkIf config.myHome.programs.git.enable (
    lib.mkMerge [
      {
        programs.difftastic = {
          enable = true;
          git.enable = true;
          git.diffToolMode = true;
        };

        programs.git = {
          enable = true;
          ignores = [ "*.swp" ];
          lfs.enable = true;

          settings = {
            user = {
              name = "Ben";
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

            url."ssh://git@github.com/".insteadOf = "https://github.com/";
          };
        };
      }

      (lib.mkIf config.myHome.programs.git.signingKey.enable (
        let
          signingKeyPath = ".ssh/github_sign";
          githubPublicSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqe4FEfKED0fJ1IETiws0aYV1lzDTBuGJfBFi+WTsJ8 ben@Bens-MBP";
        in
        {
          programs.git.settings = {
            commit.gpgsign = true;
            gpg.format = "ssh";
            user.signingKey = "~/${signingKeyPath}";
          };

          age.secrets."github-signing-key" = {
            file = "${self.inputs.secrets}/ssh/github-signing-key.age";
            symlink = false;
            path = "$HOME/${signingKeyPath}";
            mode = "600";
          };

          home.file.".ssh/github_sign.pub".text = githubPublicSigningKey;
        }
      ))

      (lib.mkIf config.myHome.programs.git.forgejo.enable (
        let
          sshKeyPath = ".ssh/git-forgejo";
        in
        {
          programs.git = {
            settings = {
              url."ssh://forgejo@git.thekoppe.com/".insteadOf = "https://git.thekoppe.com/";
            };

            includes = [
              {
                condition = "hasconfig:remote.*.url:ssh://forgejo@git.thekoppe.com/**";
                contents = {
                  user = {
                    name = "ben";
                    email = "benjamin.e.koppe@gmail.com";
                  };

                  commit.gpgsign = true;
                  gpg.format = "ssh";
                  user.signingKey = "~/${sshKeyPath}";

                  core.sshCommand = "ssh -i ~/${sshKeyPath}";
                };
              }
            ];
          };

          age.secrets."forgejo-ssh-key" = {
            file = "${self.inputs.secrets}/ssh/git-forgejo.age";
            symlink = false;
            path = "$HOME/${sshKeyPath}";
            mode = "600";
          };

          home.file.".ssh/git-forgejo.pub".text =
            builtins.readFile "${self.inputs.secrets}/ssh/git-forgejo.pub";
        }
      ))
    ]
  );
}
