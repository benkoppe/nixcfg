{
  flake.modules.hjem.browsers =
    { pkgs, ... }:
    {
      packages = [ pkgs.brave ];
    };
}
