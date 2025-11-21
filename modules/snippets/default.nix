{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./nix
    ./networks
    ./hosts
  ];

  options.mySnippets = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "hostname of the machine";
    };

    primaryUser = lib.mkOption {
      type = lib.types.str;
      description = "username of primary system user";
    };

    primaryHome = lib.mkOption (
      let
        inherit (config.mySnippets) primaryUser;
      in
      {
        type = lib.types.str;
        description = "home directory of primary system user";
        default = if pkgs.stdenv.isDarwin then "/Users/${primaryUser}" else "/home/${primaryUser}";
      }
    );
  };
}
