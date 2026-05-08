{
  flake.modules.hjem.direnv =
    { pkgs, ... }:
    {
      packages = [
        pkgs.direnv
        pkgs.nix-direnv
      ];

      rum.programs.direnv = {
        enable = true;

        integrations.nix-direnv.enable = true;
        integrations.zsh.enable = true;
      };
    };
}
