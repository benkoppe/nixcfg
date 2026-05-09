{
  flake.modules.nixos.development = {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;

      # silent = true;
    };
  };

  flake.modules.hjem.development =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        nh
        nix-output-monitor
        coreutils
        bash-completion
        killall
        wget
        zip
        unzip

        htop
        iftop
      ];
    };
}
