{
  lib,
  config,
  self,
  pkgs,
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

    extraConfig = lib.mkOption {
      type = lib.types.listOf lib.types.lines;
      default = [ ];
      description = "Additional Caddy config fragments merged into this virtual host.";
    };
  };

  config =
    let
      cfg = config.myNixOS.services.caddy;
    in
    lib.mkIf cfg.enable {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
          hash = "sha256-4qUWhrv3/8BtNCi48kk4ZvbMckh/cGRL7k+MFvXKbTw=";
        };

        virtualHosts."${cfg.subdomain}.${cfg.domain}" = {
          extraConfig = lib.concatStringsSep "\n" (
            [
              ''
                reverse_proxy localhost:${toString cfg.port}

                tls {
                  dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
                }
              ''
            ]
            ++ cfg.extraConfig
          );
        };
        environmentFile = config.age.secrets.caddy-cloudflare.path;
      };

      age.secrets.caddy-cloudflare.file = "${self.inputs.secrets}/services/caddy/cloudflare-api.age";

      networking.firewall.interfaces = {
        ${cfg.networkDevice}.allowedTCPPorts = [
          443
        ];
      };
    };
}
