{ inputs, ... }:
{
  flake.modules.hjem.herdr =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages = [
        inputs.llm-agents.packages.${system}.herdr
      ];
    };
}
