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

      my.service-vms.tailgate.modules =
        let
          authKey = config.clan.core.vars.generators.tailgate-auth-key.files.key.path;
          authKeyMnt = "/run/secrets/authKey";
        in
        [
          {
            microvm.shares = [
              {
                source = builtins.dirOf authKey;
                mountPoint = authKeyMnt;
                tag = "authKey";
                proto = "virtiofs";
              }
            ];
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

              authKeyFile = "${authKeyMnt}/key";
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
