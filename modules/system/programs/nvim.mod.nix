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
        (nvimPkgs.full.wrap { argv0 = "nvim"; })
        nvimPkgs.minimal
      ];

      environment.sessionVariables = {
        ALTERNATE_EDITOR = "";
        EDITOR = "vi";
        VISUAL = "nvim";
      };
    };

}
