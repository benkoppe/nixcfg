{
  self,
  pkgs,
  ...
}:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    shell = pkgs.bash;
    openssh.authorizedKeys.keyFiles = [
      "${self.inputs.secrets}/pve/builder-1-key.pub"
    ];
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [
    "${self.inputs.secrets}/pve/builder-1-root-key.pub"
  ];

  networking.hostName = "builder-1";
}
