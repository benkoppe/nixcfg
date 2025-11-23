{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 350;
  suffix = 50;
in
{
  inherit vm_id suffix;
  ipv4 = "${tailscale.prefix}.${toString suffix}";

  mediaLocation = "/mnt/immich/data";
}
