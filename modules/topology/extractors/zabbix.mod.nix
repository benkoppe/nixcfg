{ inputs, ... }:
{
  flake.modules.nixos."topology/extractors/zabbix" =
    { config, lib, ... }:
    let
      server = config.services.zabbixServer or { };
      web = config.services.zabbixWeb or { };
    in
    {
      options.topology.extractors.localServices.zabbix.enable =
        lib.mkEnableOption "Zabbix topology extractor"
        // {
          default = true;
        };

      config =
        lib.mkIf
          (
            config.topology.extractors.localServices.zabbix.enable
            && ((server.enable or false) || (web.enable or false))
          )
          {
            topology.icons.services.zabbix.file = inputs.selfhst-icons + "/svg/zabbix.svg";

            topology.self.services.zabbix = {
              name = "Zabbix";
              icon = "services.zabbix";
              info = lib.mkIf ((web.hostname or null) != null) "https://${web.hostname}";
              details = {
                server.text = if server.enable or false then "enabled" else "disabled";
                web.text = if web.enable or false then web.frontend or "enabled" else "disabled";
                database.text = server.database.type or web.database.type or "";
              };
            };
          };
    };
}
