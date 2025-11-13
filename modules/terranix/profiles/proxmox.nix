{
  config,
  lib,
  ...
}:
{
  options.myTerranix.profiles.proxmox.enable = lib.mkEnableOption "proxmox terraform provider";

  config = lib.mkIf config.myTerranix.profiles.proxmox.enable {

    terraform.required_providers.proxmox = {
      source = "bpg/proxmox";
      version = "0.86.0";
      # terraform-prov@pve!mytoken
    };

    provider.proxmox = {

      endpoint = "https://pve.thekoppe.com";
      # api_token = "terraform-prov@pve!mytoken";
    };
  };
}
