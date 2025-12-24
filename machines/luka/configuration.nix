{ modules, ... }:
{
  imports = with modules.nixosModules; [
    nix
  ];
}
