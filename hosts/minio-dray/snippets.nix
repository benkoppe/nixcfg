{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 375;
  suffix = 75;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  vHost = "minio.thekoppe.com";
  mntDir = "/mnt/minio";
}
