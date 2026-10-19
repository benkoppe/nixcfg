{ inputs, ... }:
{
  flake.modules.hjem.browsers =
    { pkgs, ... }:
    {
      packages = [
        pkgs.brave
        inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
