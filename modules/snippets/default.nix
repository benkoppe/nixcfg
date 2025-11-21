{ lib, ... }:
{
  imports = [
    ./nix
    ./networks
    ./hosts
  ];

  options.mySnippets.primaryUser = lib.mkOption {
    type = lib.types.str;
    description = "username of primary system user";
  };

  options.mySnippets.hostName = lib.mkOption {
    type = lib.types.str;
    description = "hostname of the machine";
  };
}
