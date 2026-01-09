{ lib, self, ... }:
{
  flake.modules.nixos.caddy =
    {
      pkgs,
      config,
      ...
    }:
    {
      imports = with self.modules.nixos; [ cloudflare-api ];

      options.my.caddy = {
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
          cfg = config.my.caddy;
        in
        {
          microvm.volumes = [
            {
              image = "caddy-data.img";
              mountPoint = config.services.caddy.dataDir;
              size = 64;
            }
          ];

          networking.firewall.allowedTCPPorts = [ 443 ];

          services.caddy = {
            enable = true;
            package = pkgs.caddy.withPlugins {
              plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
              hash = "sha256-dnhEjopeA0UiI+XVYHYpsjcEI6Y1Hacbi28hVKYQURg=";
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

            environmentFile = config.clan.core.vars.generators.cloudflare.files.api-token.path;
          };
        };
    };
}
