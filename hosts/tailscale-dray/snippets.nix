{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 300;
  suffix = 10;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";
}
