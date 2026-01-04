{ self, ... }:
let
  vHost = "garage.thekoppe.com";
  ports = {
    s3_api = 3900;
    s3_web = 3902;

    rpc_bind = 3901;
    admin = 3903;
  };
  subdomains = {
    S3 = "s3";
    web = "cdn";
    admin = "garage-admin";
  };
  mntDir = "/var/lib/garage";
in
{
  flake.clan.machines.vm-garage =
    { config, pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client

        caddy
        backup-b2
      ];

      my.caddy.virtualHosts = [
        {
          inherit vHost;
          port = 3909;
        }
      ];

      my.backup-b2.garage = {
        paths = [ mntDir ];
        restartServices = [ "garage" ];
      };

      microvm.volumes = [
        {
          image = "garage-data.img";
          mountPoint = "/var/lib/private/garage";
          size = 1024 * 50; # 50 GiB
        }
      ];

      services.caddy.extraConfig =
        let
          dnsSnippet = ''
            tls {
              dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
            }
          '';
          healthSnippet = ''
            health_uri       /health
            health_port      ${toString ports.admin}
            #health_interval 15s
            #health_timeout  5s
          '';
        in
        ''
          ${subdomains.S3}.thekoppe.com, *.${subdomains.S3}.thekoppe.com {
            reverse_proxy localhost:${toString ports.s3_api} {
              ${healthSnippet}
            }
            ${dnsSnippet}
          }

          *.${subdomains.web}.thekoppe.com {
            reverse_proxy localhost:${toString ports.s3_web} {
              ${healthSnippet}
            }
            ${dnsSnippet}
          }

          ${subdomains.admin}.thekoppe.com {
            reverse_proxy localhost:${toString ports.admin} {
              ${healthSnippet}
            }
            ${dnsSnippet}
          }
        '';

      clan.core.vars.generators = {
        garage-environment = {
          prompts.value = {
            description = "Garage environment variables";
            persist = true;
            type = "multiline";
          };
          share = true;
        };
        garage-webui-environment = {
          prompts.value = {
            description = "Garage Web UI environment variables";
            persist = true;
            type = "multiline";
          };
          share = true;
        };
      };

      services.garage = {
        enable = true;
        package = pkgs.garage_2;

        environmentFile = config.clan.core.vars.generators.garage-environment.files.value.path;
        settings = {
          replication_factor = 1;

          metadata_dir = "${mntDir}/meta";
          data_dir = "${mntDir}/data";
          db_engine = "sqlite";

          rpc_bind_addr = "[::]:${toString ports.rpc_bind}";
          rpc_public_addr = "127.0.0.1:${toString ports.rpc_bind}";

          s3_api = {
            s3_region = "garage";
            api_bind_addr = "[::]:${toString ports.s3_api}";
            root_domain = ".${subdomains.S3}.thekoppe.com";
          };

          s3_web = {
            bind_addr = "[::]:${toString ports.s3_web}";
            root_domain = ".${subdomains.web}.thekoppe.com";
            index = "index.html";
          };

          # k2v_api = {
          # api_bind_addr = "[::]:3904";
          # };

          admin = {
            api_bind_addr = "[::]:${toString ports.admin}";
          };
        };
      };

      systemd.services.garage-webui = {
        description = "Garage Web UI";
        wantedBy = [ "multi-user.target" ];
        after = [ "garage.service" ];

        serviceConfig = {
          ExecStart = "${pkgs.garage-webui}/bin/garage-webui";
          Restart = "always";

          EnvironmentFile = config.clan.core.vars.generators.garage-webui-environment.files.value.path;
        };
        environment = {
          CONFIG_PATH = "/etc/garage.toml";

          API_BASE_URL = "https://${subdomains.admin}.thekoppe.com";
          S3_REGION = "garage";
          S3_ENDPOINT_URL = "http://localhost:${toString ports.s3_api}";
        };
      };
    };
}
