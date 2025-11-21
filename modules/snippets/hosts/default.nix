{
  lib,
  config,
  self,
  ...
}:
let
  hostsDir = ../../../hosts;

  hostsWithSnippets = builtins.filter (n: builtins.pathExists "${hostsDir}/${n}/snippets.nix") (
    builtins.attrNames (builtins.readDir hostsDir)
  );

  hostSnippets = lib.genAttrs hostsWithSnippets (
    name: import "${hostsDir}/${name}/snippets.nix" { inherit lib config self; }
  );
in
{
  options.mySnippets.hosts = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;

    description = "Host-specific global configurations";

    default = hostSnippets;
  };
}
