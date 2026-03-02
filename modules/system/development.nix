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
}
