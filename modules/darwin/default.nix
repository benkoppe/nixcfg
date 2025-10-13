{ lib, ... }:
{
  options.myDarwin.primaryUser = lib.mkOption {
    type = lib.types.str;
    description = "username of primary system user";
  };

  options.myDarwin.hostName = lib.mkOption {
    type = lib.types.str;
    description = "hostname of the machine";
  };

  imports = [
    ./profiles
    ./programs
    ./system
  ];
}
