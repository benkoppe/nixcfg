{
  self,
  config,
  pkgs,
  ...
}:
let
  ports = {
    s3_api = 3900;
    s3_web = 3902;

    rpc_bind = 3901;
    admin = 3903;
  };
  mntDir = "/mnt/garage";
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy = {
      enable = true;

      virtualHosts = [
        {
          domain = "thekoppe.com";
          subdomain = "garage";
          port = 3909;
        }
      ];
    };
  };

  users = {
    users.root.openssh.authorizedKeys.keyFiles = [
      "${self.inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];
    users.garage = {
      uid = 1000;
      group = "garage";
      isSystemUser = true;
    };
    groups.garage = {
      gid = 1000;
    };
  };

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
      s3.thekoppe.com, *.s3.thekoppe.com {
        reverse_proxy localhost:${toString ports.s3_api} {
          ${healthSnippet}
        }
        ${dnsSnippet}
      }

      *.garage.thekoppe.com {
        reverse_proxy localhost:${toString ports.s3_web} {
          ${healthSnippet}
        }
        ${dnsSnippet}
      }

      garage-admin.thekoppe.com {
        reverse_proxy localhost:${toString ports.admin} {
          ${healthSnippet}
        }
        ${dnsSnippet}
      }
    '';

  services.garage = {
    enable = true;
    package = pkgs.garage_2;

    environmentFile = config.age.secrets.garage-environment.path;
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
        root_domain = ".s3.thekoppe.com";
      };

      s3_web = {
        bind_addr = "[::]:${toString ports.s3_web}";
        root_domain = ".garage.thekoppe.com";
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

      EnvironmentFile = config.age.secrets.garage-webui-environment.path;
    };
    environment = {
      CONFIG_PATH = "/etc/garage.toml";

      API_BASE_URL = "https://garage-admin.thekoppe.com";
      S3_REGION = "garage";
      S3_ENDPOINT_URL = "http://localhost:${toString ports.s3_api}";
    };
  };

  age.secrets = {
    garage-environment.file = "${self.inputs.secrets}/services/garage/environment.age";
    garage-webui-environment.file = "${self.inputs.secrets}/services/garage/webui-environment.age";
  };
}
