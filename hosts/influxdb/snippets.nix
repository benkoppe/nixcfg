{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 333;
  suffix = 33;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "influxdb.thekoppe.com";
}
