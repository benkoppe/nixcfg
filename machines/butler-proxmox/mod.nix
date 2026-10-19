let
  # Keep the current DHCP address until Butler is migrated to static networking.
  address = "10.0.1.29";
in
{
  flake.machines.butler-proxmox = {
    ip.addresses4 = [ address ];
    ssh = {
      hostName = address;
      user = "ben";
    };
  };

  flake.clan.inventory.machines.butler-proxmox = {
    tags = [
      "development"
      "butler"
    ];
  };
}
