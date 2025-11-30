{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 355;
  suffix = 55;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  dataLocation = "/mnt/forgejo";

  vHost = "git.thekoppe.com";
}
