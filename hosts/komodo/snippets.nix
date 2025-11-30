{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 390;
  suffix = 90;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "komodo2.thekoppe.com";
  port = 9120;
}
