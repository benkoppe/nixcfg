{
  lib,
  config,
  ...
}:
{
  options.myNixOS.services.nginx = {
    enable = lib.mkEnableOption "Nginx web server";

    vHost = lib.mkOption {
      type = lib.types.str;
      description = "The virtual host for the Nginx server.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      description = "The port Nginx should forward.";
    };

    networkDevice = lib.mkOption {
      type = lib.types.str;
      description = "The network device to bind to.";
      default = config.mySnippets.networks.tailscale.deviceName;
    };

    proxyWebsockets = lib.mkEnableOption "Also proxy websockets";

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        These lines go to the end of the upstream verbatim.
      '';
    };
  };

  config =
    let
      cfg = config.myNixOS.services.nginx;
    in
    lib.mkIf cfg.enable {
      myNixOS.services.acme-cloudflare = true;
      security.acme.certs."${cfg.vHost}" = {
        inherit (config.services.nginx) group;
      };

      services.nginx = {
        enable = true;

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        virtualHosts = {
          "${cfg.vHost}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.port}";
              inherit (cfg) proxyWebsockets extraConfig;
            };
          };
        };
      };

      networking.firewall.interfaces = {
        ${cfg.networkDevice}.allowedTCPPorts = [
          443
        ];
      };
    };
}
