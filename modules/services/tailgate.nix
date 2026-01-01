{
  flake.modules.nixos.tailgate =
    { config, ... }:
    {
      clan.core.vars.generators.tailgate-auth-key = {
        prompts.key = {
          description = "Tailscale auth key for tailgates";
          persist = true;
        };
        share = true;
      };

      my.service-vms.tailgate.modules = [
        {
          services.tailscale = {
            enable = true;
            openFirewall = true;

            authKeyFile = config.clan.core.vars.generators.tailgate-auth-key.files.key.path;
            useRoutingFeatures = "server";

            extraSetFlags = [
              "--ssh"
              "--advertise-exit-node"
              "--advertise-routes=10.0.0.0/24"
            ];
          };

          networking.firewall.allowedTCPPorts = [ 8088 ]; # tailscale web
        }
      ];
    };
}
