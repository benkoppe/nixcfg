{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 321;
  suffix = 21;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "pocket.thekoppe.com";
}
