{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/lldap" =
    { config, lib, ... }:
    let
      cfg = config.services.lldap or { };
      settings = cfg.settings or { };
    in
    {
      options.topology.extractors.localServices.lldap.enable =
        lib.mkEnableOption "LLDAP topology extractor"
        // {
          default = true;
        };

      config = lib.mkIf (config.topology.extractors.localServices.lldap.enable && (cfg.enable or false)) {
        topology.icons.services.lldap.file = inputs.selfhst-icons + "/svg/lldap-light.svg";

        topology.self.services.lldap = {
          name = "LLDAP";
          icon = "services.lldap";
          info = settings.http_url or "";
          details = {
            http.text = "${settings.http_host or "0.0.0.0"}:${toString (settings.http_port or 17170)}";
            ldap.text = "${settings.ldap_host or "0.0.0.0"}:${toString (settings.ldap_port or 3890)}";
            base-dn.text = settings.ldap_base_dn or "";
          };
        };
      };
    };
}
