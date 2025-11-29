{
  self,
  pkgs,
  config,
  ...
}:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

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
      "${self.inputs.secrets}/pve/nix-builder-key.pub"
    ];
  };

  networking.hostName = config.mySnippets.hostName;
}
