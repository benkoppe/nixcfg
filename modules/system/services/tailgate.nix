{ lib, ... }:
{
  flake.modules.nixos.tailgate =
    { config, ... }:
    let
      cfg = config.my.tailgate;
    in
    {
      options.my.tailgate.routes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subnets to advertise via Tailscale (e.g. 10.0.0.0/24)";
      };

      config = {
        clan.core.vars.generators.tailgate-auth-key = {
          prompts.key = {
            description = "Tailscale auth key for tailgates";
            persist = true;
          };
          share = true;
        };

        # without this, tailscale ssh doesn't work
        # see https://github.com/tailscale/tailscale/issues/4924
        security.pam.services.remote.text = config.security.pam.services.login.text;

        services.tailscale = {
          enable = true;
          openFirewall = true;

          authKeyFile = config.clan.core.vars.generators.tailgate-auth-key.files.key.path;
          useRoutingFeatures = "server";

          extraSetFlags = [
            "--ssh"
            "--advertise-exit-node"
            "--accept-routes"
          ]
          ++ lib.optional (cfg.routes != [ ]) "--advertise-routes=${lib.concatStringsSep "," cfg.routes}";
        };
      };
    };
}
