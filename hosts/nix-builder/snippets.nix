{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale;
  vm_id = 242;
in
{
  inherit vm_id;
  ipv4 = "${tailscale.prefix}.${toString vm_id}";
}
