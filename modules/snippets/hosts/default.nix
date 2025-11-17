{ lib, config, ... }:
{
  options.mySnippets.hosts = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;

    description = "Host-specific global configurations";

    default =
      let
        inherit (config.mySnippets.networks) tailscale;
      in
      {
        builder-1 =
          let
            vm_id = 240;
          in
          {
            inherit vm_id;
            ipv4 = "${tailscale.prefix}.${toString vm_id}";
          };

        adguard =
          let
            vm_id = 245;
          in
          {
            inherit vm_id;
            ipv4 = "${tailscale.prefix}.${toString vm_id}";
          };
      };
  };
}
