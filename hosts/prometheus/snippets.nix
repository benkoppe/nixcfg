{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 331;
  suffix = 31;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "prometheus.thekoppe.com";
}
