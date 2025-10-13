{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  options.myHome.programs.git = {
    enable = lib.mkEnableOption "git";
    signingKey.enable = lib.mkEnableOption "use signing key for commits";
  };

  config = lib.mkIf config.myHome.programs.git.enable (
    lib.mkMerge [
      {
        programs.git = {
          enable = true;
          ignores = [ "*.swp" ];
          userName = "Ben";
          userEmail = "koppe.development@gmail.com";
          lfs = {
            enable = true;
          };
          extraConfig = {
            init.defaultBranch = "main";
            core = {
              editor = "vim";
              autocrlf = "input";
            };
            pull.rebase = true;
            rebase.autoStash = true;
          };
        };
      }

      (lib.mkIf config.myHome.programs.git.signingKey.enable (
        let
          signingKeyPath = ".ssh/github_sign";
          githubPublicSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqe4FEfKED0fJ1IETiws0aYV1lzDTBuGJfBFi+WTsJ8 ben@Bens-MBP";
        in
        {
          programs.git.extraConfig = {
            commit.gpgsign = true;
            gpg.format = "ssh";
            user.signingKey = "~/${signingKeyPath}";
          };

          age.secrets."github-signing-key" = {
            file = "${self.inputs.secrets}/github-signing-key.age";
            symlink = false;
            path = "$HOME/${signingKeyPath}";
            mode = "600";
          };

          home.file.".ssh/github_sign.pub".text = githubPublicSigningKey;
        }
      ))
    ]
  );
}
