{ config, inputs, ... }:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy = {
      enable = true;
      networkDevices = [ ];
      virtualHosts = [
        {
          vHost = "git.thekoppe.com";
          address = "10.1.1.55";
          port = 3000;
        }
        {
          vHost = "pocket.thekoppe.com";
          address = "10.1.1.21";
          port = 1411;
        }
      ];
    };
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "ba89c3b8-1df3-4d31-9030-54e8475c3c25" = {
        credentialsFile = config.age.secrets.cloudflared-dray.path;
        default = "http_status:404";
        ingress = {
          "git.thekoppe.com" = {
            service = "https://localhost:443";
            originRequest.originServerName = "git.thekoppe.com";
          };
          "pocket.thekoppe.com" = {
            service = "https://localhost:443";
            originRequest.originServerName = "pocket.thekoppe.com";
          };
        };
      };
    };
  };

  age.secrets.cloudflared-dray.file = "${inputs.secrets}/services/cloudflare/dray-tunnel-creds.age";
}
