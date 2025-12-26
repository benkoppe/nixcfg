{
  inputs,
  lib,
  ...
}:
{
  # automatically import all files in <flake>/machines with name "terranix.nix" as configurations
  imports = [ ((inputs.import-tree.filter (lib.hasSuffix "terranix.nix")) ../../../machines) ];
}
