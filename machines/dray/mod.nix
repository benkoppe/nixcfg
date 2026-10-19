{
  flake.machines.dray = { };

  flake.clan.inventory.machines.dray = {
    tags = [ "development" ];
  };

  # Use Dray as the shared cache proxy.
  flake.clan.inventory.instances.ncps.roles.server.machines.dray = { };
}
