{ config, ... }:
let
  inherit (config.mySnippets.networks) tailscale home;
  vm_id = 245;
in
{
  inherit vm_id;
  ipv4 = "${tailscale.prefix}.${toString vm_id}";
  home_ipv4 = "${home.prefix}.102";
}
