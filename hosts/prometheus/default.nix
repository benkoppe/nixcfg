{ config, ... }:
let
  inherit (config.mySnippets) hosts networks hostName;
  inherit (hosts.${hostName}) vHost;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy = {
      enable = true;

      networkDevices = [
        networks.tailscale.deviceName
      ];

      virtualHosts = [
        {
          inherit vHost;
          inherit (config.services.prometheus) port;
        }
      ];
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;

    webExternalUrl = "https://${vHost}";

    extraFlags = [ "--web.enable-remote-write-receiver" ];
  };
}
