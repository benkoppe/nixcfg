{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 330;
  suffix = 30;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "alloy.thekoppe.com";
}
