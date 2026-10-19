{
  flake.modules.nixos.development = {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = false;
      nix-direnv.enable = true;

      # silent = true;
    };
  };
}
