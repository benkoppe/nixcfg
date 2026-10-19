{ self, ... }:
{
  flake.modules.nixos."topology/extractors" = {
    imports = [
      self.modules.nixos."topology/extractors/cloudflared"
      self.modules.nixos."topology/extractors/garage"
      self.modules.nixos."topology/extractors/komodo"
      self.modules.nixos."topology/extractors/lldap"
      self.modules.nixos."topology/extractors/pocket-id"
      self.modules.nixos."topology/extractors/resilio"
      self.modules.nixos."topology/extractors/tang"
      self.modules.nixos."topology/extractors/zabbix"
    ];
  };
}
