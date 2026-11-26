{ inputs, ... }:
{
  flake.modules.hjem.nvim =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      nvimPkgs = inputs.nvim-flake.packages.${system};
    in
    {
      packages = [
        nvimPkgs.full
        nvimPkgs.minimal
      ];

      shellAliases.v = "nvim";

      environment.sessionVariables = {
        ALTERNATE_EDITOR = "";
        EDITOR = "vi";
        VISUAL = "nvim";
      };
    };

}
