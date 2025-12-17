{
  inputs,
  inputs',
  pkgs,
  config,
  ...
}:
{
  myNixOS = {
    profiles.proxmox-vm.enable = true;

    services.hercules-ci-agent = {
      enable = true;
    };

    programs.nix.accessTokens.enable = true;
  };

  imports = [ ./cache.nix ];

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    shell = pkgs.bash;
    openssh.authorizedKeys.keyFiles = [
      "${inputs.secrets}/pve/nix-builder-key.pub"
    ];
  };

  environment.systemPackages = [
    inputs'.colmena.packages.colmena
  ];

  networking =
    let
      inherit (config.mySnippets.networks) tailscale;
    in
    {
      inherit (config.mySnippets) hostName;

      interfaces."eth0".ipv4.addresses = [
        {
          address = "${tailscale.prefix}.100";
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = tailscale.gateway;
        interface = "eth0";
      };
      nameservers = [ "192.168.1.1" ];
    };

}
