{
  lib,
  config,
  self,
  ...
}:
{
  options.myNixOS.services.caddy = {
    enable = lib.mkEnableOption "Caddy web server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain name for the Caddy server.";
      default = "thekoppe.com";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "The subdomain for the Caddy server.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port Caddy should forward.";
    };

    networkDevice = lib.mkOption {
      type = lib.types.str;
      description = "The network device to bind to.";
      default = config.mySnippets.networks.tailscale.deviceName;
    };
  };

  config =
    let
      cfg = config.myNixOS.services.caddy;
    in
    lib.mkIf cfg.enable {
      security.acme = {
        acceptTerms = true;
        defaults.email = "koppe.development@gmail.com";

        certs."${cfg.domain}" = {
          inherit (config.services.caddy) group;

          inherit (cfg) domain;
          extraDomainNames = [ "*.${cfg.domain}" ];
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          dnsPropagationCheck = true;
          environmentFile = config.age.secrets.caddy-cloudflare.path;
        };
      };

      services.caddy = {
        enable = true;

        virtualHosts."${cfg.subdomain}.${cfg.domain}" = {
          extraConfig =
            let
              certloc = "/var/lib/acme/${cfg.domain}";
            in
            ''
              reverse_proxy http://127.0.0.1:${toString cfg.port}

              tls ${certloc}/cert.pem ${certloc}/key.pem {
                protocols tls1.3
              }
            '';
        };
      };

      age.secrets.caddy-cloudflare.file = "${self.inputs.secrets}/services/caddy/cloudflare-api.age";

      networking.firewall.interfaces = {
        ${cfg.networkDevice}.allowedTCPPorts = [
          80
          443
        ];
      };
    };
}
