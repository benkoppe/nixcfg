{ self, ... }:
{
  flake.modules.nixos.cloudflared-machine = {
    imports = with self.modules.nixos; [
      microvms_client
      cloudflared
    ];
  };

  flake.clan.machines.vm-cloudflared-luka = {
    imports = with self.modules.nixos; [
      cloudflared-machine
    ];

    topology.id = "luka-cloudflared";
  };

  flake.clan.machines.vm-cloudflared-dray = {
    imports = with self.modules.nixos; [
      cloudflared-machine
    ];

    topology.id = "dray-cloudflared";
  };
}
