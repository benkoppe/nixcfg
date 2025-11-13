{ lib, ... }:
{
  options.myTerranix.hostName = lib.mkOption {
    type = lib.types.str;
    description = "hostname of the machine";
  };

  imports = [
    ./profiles
  ];
}
