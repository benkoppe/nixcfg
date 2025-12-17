{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 310;
  suffix = 100;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "cache.thekoppe.com";
}
