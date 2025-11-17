{ lib, ... }:
{
  options = {
    mySnippets.networks = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            prefix = lib.mkOption {
              type = lib.types.str;
            };
            gateway = lib.mkOption {
              type = lib.types.str;
            };
          };
        }
      );

      default = {
        tailscale =
          let
            prefix = "10.192.168";
          in
          {
            inherit prefix;
            gateway = "${prefix}.1";
          };
      };
    };
  };
}
