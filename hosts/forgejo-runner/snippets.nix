{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 356;
  suffix = 56;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";
}
