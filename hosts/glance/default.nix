{
  config,
  self,
  ...
}:
let
  inherit (config.mySnippets) hosts;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  age.secrets.glance-environment.file = "${self.inputs.secrets}/services/glance/environment.age";

  services.glance = {
    enable = true;
    openFirewall = true;

    environmentFile = config.age.secrets.glance-environment.path;
    settings = {
      server.host = "0.0.0.0";
      pages = [
        {
          name = "Koppelab";
          width = "slim";
          hide-desktop-navigation = true;
          center-vertically = true;
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                }
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Public Services";

                  sites = [
                    {
                      title = "Forgejo";
                      url = "https://${hosts.forgejo.vHost}";
                      icon = "di:forgejo";
                      description = "Git Forge";
                    }
                  ];
                }
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Private Services";

                  sites = [
                    {
                      title = "Proxmox VE";
                      url = "https://pve.thekoppe.com";
                      icon = "di:proxmox";
                      description = "Virtualization Host";
                    }
                    {
                      title = "Garage";
                      url = "https://${hosts.garage-dray.vHost}";
                      icon = "di:garage";
                      description = "S3 Object Store";
                    }
                    {
                      title = "Immich";
                      url = "https://${hosts.immich.vHost}";
                      icon = "di:immich";
                      description = "Photos";
                    }
                    {
                      title = "Lldap";
                      url = "https://${hosts.lldap.vHost}";
                      icon = "di:lldap-dark";
                      description = "Auth Users";
                    }
                    {
                      title = "Pocket ID";
                      url = "https://${hosts.pocket-id.vHost}";
                      icon = "di:pocket-id";
                      description = "Auth Login";
                    }
                    {
                      title = "Vaultwarden";
                      url = "https://${hosts.vaultwarden.vHost}";
                      icon = "di:vaultwarden-light";
                      description = "Password Manager";
                    }
                  ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "dns-stats";
                  service = "adguard";
                  url = "https://${hosts.adguard.vHost}";
                  username = "ben";
                  password = ''''${ADGUARD_PASSWORD}'';
                }
              ];
            }
          ];
        }
      ];
    };
  };

  networking.firewall.interfaces =
    let
      inherit (config.services.glance.settings.server) port;
      inherit (config.mySnippets) networks;
    in
    {
      ${networks.tailscale.deviceName}.allowedTCPPorts = [
        port
      ];
    };
}
