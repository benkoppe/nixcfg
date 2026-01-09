{ self, lib, ... }:
{
  flake.clan.machines.vm-tailgate =
    { config, ... }:
    let
      cfg = config.my.tailgate;
    in
    {
      imports = with self.modules.nixos; [
        microvms_client
      ];

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

        microvm.volumes = [
          {
            image = "tailscale-state.img";
            mountPoint = "/var/lib/tailscale";
            size = 64;
          }
        ];

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

        # from https://wiki.nixos.org/wiki/Tailscale
        networking.nftables.enable = true;
        networking.firewall = {
          enable = true;
          # Always allow traffic from your Tailscale network
          trustedInterfaces = [ "tailscale0" ];
          # Allow the Tailscale UDP port through the firewall
          allowedUDPPorts = [ config.services.tailscale.port ];
        };

        # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
        # This avoids the "iptables-compat" translation layer issues.
        systemd.services.tailscaled.serviceConfig.Environment = [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];
        # -----
      };
    };
}
