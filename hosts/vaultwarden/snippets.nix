{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 322;
  suffix = 22;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";
}
