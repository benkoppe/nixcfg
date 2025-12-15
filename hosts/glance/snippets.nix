{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 380;
  suffix = 80;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "lab.thekoppe.com";
}
