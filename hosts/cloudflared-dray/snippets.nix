{ config, ... }:
let
  inherit (config.mySnippets.networks) cloudflare tailscale;
  vm_id = 305;
  suffix = 105;
in
{
  inherit vm_id suffix;
  ipv4 = "${cloudflare.prefix}.${toString suffix}";
  targetHost = "${tailscale.prefix}.${toString suffix}";
}
