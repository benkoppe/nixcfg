let
  address = "172.16.85.129";
in
{
  flake.machines.butler-fusion = {
    ip.addresses4 = [ address ];
    ssh.hostName = address;
  };

  flake.clan.inventory.machines.butler-fusion = {
    tags = [
      "development"
      "butler"
    ];
  };
}
