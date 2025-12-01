{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 370;
  suffix = 70;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "garage.thekoppe.com";
}
