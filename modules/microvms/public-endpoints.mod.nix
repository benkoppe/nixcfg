{ self, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  flake.modules.nixos.public-endpoints = {
    options.my."public-endpoints" = mkOption {
      default = { };
      description = "Canonical public endpoints exposed by this machine.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              vHost = mkOption {
                type = types.str;
                description = "Public virtual host for this endpoint.";
              };

              serviceName = mkOption {
                type = types.str;
                default = name;
                description = "Human/service topology name for this endpoint.";
              };
            };
          }
        )
      );
    };
  };

  flake.modules.nixos.public-endpoints_caddy =
    { config, ... }:
    let
      endpoints = config.my."public-endpoints";

      caddyEndpoints = lib.filterAttrs (_: endpoint: endpoint.caddy != null) endpoints;
    in
    {
      imports = with self.modules.nixos; [
        caddy
      ];

      options.my.public-endpoints = mkOption {
        type = types.attrsOf (
          types.submodule {
            options.caddy = mkOption {
              default = null;
              description = "Caddy reverse proxy settings for this endpoint.";
              type = types.nullOr (
                types.submodule {
                  options = {
                    address = mkOption {
                      type = types.str;
                      default = "localhost";
                      description = "Caddy upstream address.";
                    };

                    port = mkOption {
                      type = types.int;
                      description = "Caddy upstream port.";
                    };

                    insecureTLS = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Whether Caddy should skip upstream TLS verification.";
                    };

                    reverseProxyExtraConfig = mkOption {
                      type = types.lines;
                      default = "";
                      description = "Extra reverse_proxy config.";
                    };

                    extraConfig = mkOption {
                      type = types.listOf types.lines;
                      default = [ ];
                      description = "Extra Caddy virtual host config.";
                    };
                  };
                }
              );
            };
          }
        );
      };

      config.my.caddy.virtualHosts = lib.mapAttrsToList (_: endpoint: {
        inherit (endpoint) vHost;
        inherit (endpoint.caddy)
          address
          port
          insecureTLS
          reverseProxyExtraConfig
          extraConfig
          ;
      }) caddyEndpoints;
    };

  flake.modules.nixos.public-endpoints_cloudflared = {
    options.my.public-endpoints = mkOption {
      type = types.attrsOf (
        types.submodule {
          options.cloudflared = mkOption {
            default = null;
            description = "Cloudflared origin settings for this endpoint.";
            type = types.nullOr (
              types.submodule {
                options = {
                  scheme = mkOption {
                    type = types.enum [
                      "http"
                      "https"
                    ];
                    default = "https";
                    description = "Scheme cloudflared uses to contact the origin.";
                  };

                  port = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Origin port for cloudflared. Null means scheme default.";
                  };

                  originServerName = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "SNI/origin server name. Defaults to vHost.";
                  };
                };
              }
            );
          };
        }
      );
    };
  };
}
