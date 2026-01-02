{ self, lib, ... }:
{
  flake.modules.nixos.nginx =
    { config, ... }:
    {
      imports = with self.modules.nixos; [ cloudflare-acme ];

      options.my.nginx = {
        vHost = lib.mkOption {
          type = lib.types.str;
          description = "The virtual host for the Nginx server.";
        };

        port = lib.mkOption {
          type = lib.types.int;
          description = "The port Nginx should forward.";
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
          cfg = config.my.nginx;
        in
        {
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

          networking.firewall = {
            allowedTCPPorts = [ 443 ];
          };
        };
    };
}
