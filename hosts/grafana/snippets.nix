{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 332;
  suffix = 32;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "grafana.thekoppe.com";
}
