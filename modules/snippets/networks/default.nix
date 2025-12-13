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
              type = lib.types.nullOr lib.types.str;
            };
            bridge = lib.mkOption {
              type = lib.types.str;
            };
            deviceName = lib.mkOption {
              type = lib.types.str;
              description = "typical name for devices on this network";
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
            bridge = "vxnetts";
            deviceName = "eth_ts";
          };

        newt =
          let
            prefix = "10.0.0";
          in
          {
            inherit prefix;
            gateway = "${prefix}.1";
            bridge = "vxnetnwt";
            deviceName = "eth_newt";
          };

        ldap =
          let
            prefix = "10.155.155";
          in
          {
            inherit prefix;
            bridge = "vxnet2";
            deviceName = "eth_ldap";
          };

        home =
          let
            prefix = "192.168.1";
          in
          {
            inherit prefix;
            gateway = "${prefix}.1";
            bridge = "vmbr0";
            deviceName = "eth_home";
          };

        obs =
          let
            prefix = "10.40.40";
          in
          {
            inherit prefix;
            bridge = "vxnetobs";
            deviceName = "eth_obs";
          };
      };
    };
  };
}
