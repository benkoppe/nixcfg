{ inputs, ... }:
{
  flake.modules.hjem.direnv =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages = [
        pkgs.direnv
        pkgs.nix-direnv
        inputs.direnv-instant.packages.${system}.default
      ];

      rum.programs.direnv = {
        enable = true;

        integrations.nix-direnv.enable = true;
        integrations.zsh.enable = false;
      };

      rum.programs.zsh.initConfig = lib.mkAfter ''
        eval "$(direnv-instant hook zsh)"
      '';
    };
}
