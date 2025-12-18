{ config, lib, ... }:
{
  myNixOS = {
    profiles.proxmox-vm.enable = true;

    services.tailscale-server.enable = true;

    services.caddy = {
      enable = true;

      virtualHosts = [
        {
          vHost = "pve.thekoppe.com";
          address = "https://10.192.168.1";
          port = 8006;
          insecureTLS = true;
        }
        {
          vHost = "pbs.thekoppe.com";
          address = "https://10.192.168.130";
          port = 8007;
          insecureTLS = true;
        }
        {
          vHost = "files.thekoppe.com";
          address = "10.192.168.204";
          port = 8081;
        }
        {
          vHost = "office.thekoppe.com";
          address = "10.192.168.204";
          port = 8080;
        }
      ];
    };
  };

  # tailscale web isn't built into the module
  # this provides metrics
  systemd.services.tailscaled-web =
    let
      # flags to pass to `tailscale web`
      webFlags = [
        "--readonly"
        "--listen"
        "10.192.168.10:8088"
      ];
    in
    lib.mkIf (webFlags != [ ]) {
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe config.services.tailscale.package} web ${lib.escapeShellArgs webFlags}";
        Restart = "always";
        RestartSec = 2;
      };
    };

  networking =
    let
      inherit (config.mySnippets.networks) tailscale;
    in
    {
      inherit (config.mySnippets) hostName;

      interfaces."eth0".ipv4.addresses = [
        {
          address = "${tailscale.prefix}.10";
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = tailscale.gateway;
        interface = "eth0";
      };
      nameservers = [ "192.168.1.1" ];

      firewall.interfaces."eth0".allowedTCPPorts = [ 8088 ]; # tailscale web
    };
}
