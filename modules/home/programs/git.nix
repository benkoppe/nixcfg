{
  config,
  lib,
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
        programs = {
          difftastic = {
            enable = true;
            git.enable = true;
            git.diffToolMode = true;
          };

          mergiraf.enable = true;

          git = {
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
        };
      }

      (lib.mkIf config.myHome.programs.git.signingKey.enable {
        programs.git.settings = {
          commit.gpgsign = true;
          gpg.format = "ssh";
          user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6fpMM43mpq3bQajVwztaNe9cIbzy6QYZO5+9t9Wv+n";
        };
      })

      # (lib.mkIf config.myHome.programs.git.forgejo.enable (
      #   let
      #     sshKeyPath = ".ssh/git-forgejo";
      #   in
      #   {
      #     programs.git = {
      #       # settings = {
      #       #   url."ssh://forgejo@${config.mySnippets.hosts.forgejo.ipv4}/".insteadOf =
      #       #     "https://git.thekoppe.com/";
      #       # };
      #
      #       includes = [
      #         {
      #           condition = "hasconfig:remote.*.url:https://git.thekoppe.com/**";
      #           contents = {
      #             user = {
      #               name = "ben";
      #               email = "benjamin.e.koppe@gmail.com";
      #             };
      #
      #             commit.gpgsign = true;
      #             gpg.format = "ssh";
      #             user.signingKey = "~/${sshKeyPath}";
      #
      #             core.sshCommand = "ssh -i ~/${sshKeyPath}";
      #           };
      #         }
      #       ];
      #     };
      #
      #     age.secrets."forgejo-ssh-key" = {
      #       file = "${inputs.secrets}/ssh/git-forgejo.age";
      #       symlink = false;
      #       path = "$HOME/${sshKeyPath}";
      #       mode = "600";
      #     };
      #
      #     home.file.".ssh/git-forgejo.pub".text = builtins.readFile "${inputs.secrets}/ssh/git-forgejo.pub";
      #   }
      # ))
    ]
  );
}
