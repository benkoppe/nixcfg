{
  config,
  lib,
  self,
  ...
}:
{
  # see <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/proxmox-lxc.nix>
  imports = [ "${self.inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix" ];

  options.myNixOS.profiles.proxmox-lxc = {
    enable = lib.mkEnableOption "profile for proxmox LXC's";

    privileged = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable privileged mounts
      '';
    };
    manageNetwork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to manage network interfaces through nix options
        When false, systemd-networkd is enabled to accept network
        configuration from proxmox.
      '';
    };
    manageHostName = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to manage hostname through nix options
        When false, the hostname is picked up from /etc/hostname
        populated by proxmox.
      '';
    };
  };

  config = lib.mkMerge [
    {
      proxmoxLXC.enable = lib.mkDefault false;
    }
    (lib.mkIf config.myNixOS.profiles.proxmox-lxc.enable {
      myNixOS.profiles.base.enable = true;

      proxmoxLXC =
        let
          cfg = config.myNixOS.profiles.proxmox-lxc;
        in
        {
          enable = true;
          privileged = cfg.privileged;
          manageNetwork = cfg.manageNetwork;
          manageHostName = cfg.manageHostName;
        };

      security.pam.services.sshd.allowNullPassword = true;
      services.fstrim.enable = false; # Let Proxmox host handle fstrim
    })
  ];
}
