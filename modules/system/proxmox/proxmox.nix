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
        self.modules.nixos."proxmox/network-pvevirt"
        self.modules.nixos."proxmox/network-cluster0"
      ];

      nixpkgs.overlays = [
        inputs.proxmox-nixos.overlays.x86_64-linux

        (final: prev: rec {
          pve-qemu-server = prev.pve-qemu-server.overrideAttrs (old: {
            postFixup = old.postFixup + ''
              find $out/lib $out/libexec -type f | xargs sed -i \
                -e "s|/usr/libexec/virtiofsd|${final.virtiofsd}/libexec/virtiofsd|g"
            '';
          });

          pve-ha-manager = prev.pve-ha-manager.override {
            inherit pve-qemu-server;
          };

          proxmox-ve = prev.proxmox-ve.override {
            inherit pve-qemu-server;
            inherit pve-ha-manager;
          };
        })
      ];

      services.proxmox-ve = {
        enable = true;
        ipAddress = lib.mkDefault "192.168.1.217";
      };

      environment.systemPackages = with pkgs; [
        cdrkit # needed to create cloudinit drives
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
