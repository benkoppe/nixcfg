{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
in
{
  vm_id = 999;
  ipv4 = "${tailscale.prefix}.99";

  targetHost = "russ";
}
