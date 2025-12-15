{
  config,
  inputs,
  ...
}:
let
  inherit (config.mySnippets) hosts;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  age.secrets.glance-environment.file = "${inputs.secrets}/services/glance/environment.age";

  services.glance = {
    enable = true;
    openFirewall = true;

    environmentFile = config.age.secrets.glance-environment.path;
    settings = {
      server.host = "0.0.0.0";
      branding = {
        app-name = "Koppelab";
        custom-footer =
          let
            url = "https://github.com/benkoppe/glance";
            # releaseUrl = "https://github.com/glanceapp/glance/releases/tag/{{ .App.Version }}";
          in
          ''
            <div>
              <a class="size-h3" href="${url}" target="_blank" rel="noreferrer">Glance</a>
              <a class="visited-indicator" title="Custom fork" href="${url}" target="_blank" rel="noreferrer">${config.services.glance.package.version}</a>
            </div>
          '';
      };
      pages = [
        {
          name = "Home";
          slug = "";
          width = "slim";
          # hide-desktop-navigation = true;
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
                    {
                      title = "Komodo";
                      url = "https://komodo.thekoppe.com";
                      icon = "di:komodo";
                      description = "Docker Control";
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
        {
          name = "More";
          width = "slim";
          center-vertically = true;
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Observability";

                  sites = [
                    {
                      title = "Grafana";
                      url = "https://${hosts.grafana.vHost}";
                      icon = "di:grafana";
                      description = "Visualizations";
                    }
                    {
                      title = "Prometheus";
                      url = "https://${hosts.prometheus.vHost}";
                      icon = "di:prometheus";
                      description = "Metrics Database";
                    }
                    {
                      title = "Alloy";
                      url = "https://${hosts.alloy.vHost}";
                      icon = "di:alloy";
                      description = "Telemetry Collector";
                    }
                    {
                      title = "InfluxDB";
                      url = "https://${hosts.influxdb.vHost}";
                      icon = "di:influxdb";
                      description = "Time-Series Store";
                    }
                  ];
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
