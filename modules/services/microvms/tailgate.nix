{ self, ... }:
{
  flake.clan.machines.vm-tailgate =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        microvms_client
      ];

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
          "--advertise-routes=10.0.0.0/24"
          "--accept-routes"
        ];
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
}
