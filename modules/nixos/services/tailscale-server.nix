{
  lib,
  config,
  inputs,
  ...
}:
{
  options.myNixOS.services.tailscale-server = {
    enable = lib.mkEnableOption "Tailscale configured for the server";
  };

  config = lib.mkIf config.myNixOS.services.tailscale-server.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;

      authKeyFile = config.age.secrets.tailscale-key.path;
      useRoutingFeatures = "server";

      extraSetFlags = [
        "--ssh"
        "--advertise-exit-node"
        "--advertise-routes=10.192.168.0/24"
      ];

      interfaceName = config.mySnippets.networks.tailscale.deviceName;
    };

    age.secrets.tailscale-key.file = "${inputs.secrets}/services/tailscale/auth-key.age";
  };
}
