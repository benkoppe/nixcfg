{
  config,
  inputs,
  lib,
  ...
}:
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
        {
          vHost = "komodo2.thekoppe.com";
          address = "10.192.168.90";
          port = 9120;
        }
        {
          vHost = "komodo.thekoppe.com";
          address = "10.0.0.210";
          port = 9120;
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
        ingress =
          let
            hosts = [
              "git.thekoppe.com"
              "pocket.thekoppe.com"
              "komodo2.thekoppe.com"
              "komodo.thekoppe.com"
            ];
          in
          lib.genAttrs hosts (host: {
            service = "https://localhost:443";
            originRequest.originServerName = host;
          });
      };
    };
  };

  age.secrets.cloudflared-dray.file = "${inputs.secrets}/services/cloudflare/dray-tunnel-creds.age";
}
