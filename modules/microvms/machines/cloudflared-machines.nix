{ self, ... }:
{
  flake.clan.machines.vm-cloudflared-luka = {
    imports = with self.modules.nixos; [
      microvms_client
      cloudflared
    ];

    # my.cloudflared.ingress = {
    #   "pocket.thekoppe.com" = {
    #     service = "https://10.0.0.5";
    #     originRequest.originServerName = "pocket.thekoppe.com";
    #   };
    #   "git.thekoppe.com" = {
    #     service = "https://10.0.0.8";
    #     originRequest.originServerName = "git.thekoppe.com";
    #   };
    # };
  };

  flake.clan.machines.vm-cloudflared-dray = {
    imports = with self.modules.nixos; [
      microvms_client
      cloudflared
    ];

    my.cloudflared.ingress = {
      "pocket.thekoppe.com" = {
        service = "https://10.1.0.5";
        originRequest.originServerName = "pocket.thekoppe.com";
      };
      "git.thekoppe.com" = {
        service = "https://10.1.0.8";
        originRequest.originServerName = "git.thekoppe.com";
      };
      "komodo.thekoppe.com" = {
        service = "https://10.1.0.9";
        originRequest.originServerName = "komodo2.thekoppe.com";
      };
    };
  };
}
