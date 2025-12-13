{ config, ... }:
let
  inherit (config.mySnippets) hosts networks hostName;
  inherit (hosts.${hostName}) vHost;
  port = 12345;
  proxmoxOTLPPort = 4318;
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

  services.alloy = {
    enable = true;

    configPath = "/etc/alloy";
  };

  environment.etc."alloy/config.alloy" = {
    text = ''
      otelcol.receiver.otlp "proxmox" {
        http {
          endpoint = "0.0.0.0:${toString proxmoxOTLPPort}"
        }
        output {
          metrics = [otelcol.exporter.prometheus.to_prom.input]
        }
      }

      otelcol.exporter.prometheus "to_prom" {
        forward_to = [prometheus.remote_write.default.receiver]
      }

      prometheus.remote_write "default" {
        endpoint {
          url = "https://${hosts.prometheus.vHost}/api/v1/write"

          // basic_auth {
          //   username = "admin"
          //   password = "admin"
          // }
        }
      }
    '';
  };

  networking.firewall.interfaces =
    let
      inherit (config.mySnippets) networks;
    in
    {
      ${networks.tailscale.deviceName}.allowedTCPPorts = [
        proxmoxOTLPPort
      ];
    };
}
