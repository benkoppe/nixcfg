{ config, ... }:
let
  inherit (config.mySnippets) hosts networks hostName;
  inherit (hosts.${hostName}) vHost;
  port = 8086;
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
          inherit vHost port;
        }
      ];
    };
  };

  services.influxdb2 = {
    enable = true;
  };

  networking.firewall.interfaces =
    let
      inherit (config.mySnippets) networks;
    in
    {
      ${networks.obs.deviceName}.allowedTCPPorts = [
        port
      ];
    };

}
