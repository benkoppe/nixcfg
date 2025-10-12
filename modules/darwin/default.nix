{ lib, ... }:
{
  options.myDarwin.primaryUser = lib.mkOption {
    type = lib.types.str;
    description = "username of primary system user";
  };

  imports = [
    ./profiles
    ./programs
    ./system
  ];
}
