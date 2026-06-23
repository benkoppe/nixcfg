{ inputs, ... }:
{
  flake.modules.hjem.direnv =
    { pkgs, ... }:
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
        integrations.zsh.enable = true;
      };
    };
}
