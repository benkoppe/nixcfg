{
  inputs,
  lib,
  self,
  ...
}:
{
  flake.modules.nixos.proxmox =
    { pkgs, ... }:
    {
      imports = [
        inputs.proxmox-nixos.nixosModules.proxmox-ve
        self.modules.nixos."proxmox/virtnetwork"
      ];

      nixpkgs.overlays = [
        inputs.proxmox-nixos.overlays.x86_64-linux
      ];

      services.proxmox-ve = {
        enable = true;
        ipAddress = "192.168.1.217";
      };

      # cdrkit needed to create cloudinit drives
      environment.systemPackages = with pkgs; [
        cdrkit
      ];

      services.openssh = {
        # fixes problems with proxmox-nixos
        settings.AcceptEnv = lib.mkForce [
          "LANG"
          "LC_*"
        ];
        # fixes problems with clan integration
        hostKeys = [
          {
            bits = 4096;
            path = "/etc/ssh/ssh_host_rsa_key";
            type = "rsa";
          }
        ];
      };
    };
}
