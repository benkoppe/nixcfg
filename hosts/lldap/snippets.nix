{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 320;
  suffix = 20;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "lldap.thekoppe.com";
}
