{ inputs, ... }:
{
  flake.modules.hjem.direnv =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      direnvInstant = inputs.direnv-instant.packages.${system}.default;
    in
    {
      packages = [
        pkgs.direnv
        pkgs.nix-direnv
        direnvInstant
      ];

      rum.programs.direnv = {
        enable = true;

        integrations.nix-direnv.enable = true;
        integrations.nushell.enable = true;
        integrations.zsh.enable = false;
      };

      rum.programs.zsh.initConfig = lib.mkAfter ''
        eval "$(${lib.getExe direnvInstant} hook zsh)"
      '';
    };
}
