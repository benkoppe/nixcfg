{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  options.myNixOS.services.caddy = {
    enable = lib.mkEnableOption "Caddy web server";

    networkDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The network devices to bind to.";
      default = [ config.mySnippets.networks.tailscale.deviceName ];
    };

    virtualHosts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            vHost = lib.mkOption {
              type = lib.types.str;
              description = "The virtual host for the Caddy server.";
            };

            address = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = "The address Caddy should forward to.";
            };

            port = lib.mkOption {
              type = lib.types.int;
              description = "The port Caddy should forward.";
            };

            insecureTLS = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable tls_insecure_skip_verify for the reverse proxy.";
            };

            reverseProxyExtraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Additional Caddy reverse_proxy config fragment.";
            };

            extraConfig = lib.mkOption {
              type = lib.types.listOf lib.types.lines;
              default = [ ];
              description = "Additional Caddy config fragments merged into this virtual host.";
            };
          };
        }
      );
      description = "List of Caddy virtual hosts to automatically configure.";
      default = [ ];
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
          hash = "sha256-ea8PC/+SlPRdEVVF/I3c1CBprlVp1nrumKM5cMwJJ3U=";
        };

        virtualHosts = lib.foldl' lib.recursiveUpdate { } (
          map (vh: {
            "${vh.vHost}" = {
              extraConfig = lib.concatStringsSep "\n" (
                [
                  ''
                    reverse_proxy ${vh.address}:${toString vh.port} { 
                      ${
                        if vh.insecureTLS then
                          ''
                            transport http {
                              tls_insecure_skip_verify
                            }
                          ''
                        else
                          ""
                      }
                      ${vh.reverseProxyExtraConfig}
                    }

                    tls {
                      dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
                    }
                  ''
                ]
                ++ vh.extraConfig
              );
            };
          }) cfg.virtualHosts
        );

        environmentFile = config.age.secrets.caddy-cloudflare.path;
      };

      age.secrets.caddy-cloudflare.file = "${inputs.secrets}/services/caddy/cloudflare-api.age";

      # open firewall for each network device
      networking.firewall.interfaces = lib.foldl' lib.recursiveUpdate { } (
        map (dev: {
          ${dev}.allowedTCPPorts = [ 443 ];
        }) cfg.networkDevices
      );
    };
}
