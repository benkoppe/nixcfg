{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  githubPublicSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqe4FEfKED0fJ1IETiws0aYV1lzDTBuGJfBFi+WTsJ8 ben@Bens-MBP";
in
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

      (lib.mkIf config.myHome.programs.git.signingKey.enable {
        programs.git.extraConfig = {
          commit.gpgsign = true;
          gpg.format = "ssh";
          user.signingKey = config.age.secrets."github-signing-key".path;
        };

        age.secrets."github-signing-key".file = "${self.inputs.secrets}/github-signing-key.age";

        home.file.".ssh/github_sign.pub".text = githubPublicSigningKey;
      })
    ]
  );
}
