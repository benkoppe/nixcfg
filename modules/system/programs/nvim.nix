{ inputs, ... }:
{
  flake.modules.hjem.nvim =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages = [ inputs.nvim-flake.packages.${system}.default ];
    };

}
