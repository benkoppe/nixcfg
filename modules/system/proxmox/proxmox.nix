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

        (
          final: prev:
          let
            # Patch virtiofsd path in pve-qemu-server
            pve-qemu-server' = prev.pve-qemu-server.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ final.virtiofsd ];
              postFixup = (old.postFixup or "") + ''
                find $out/lib $out/libexec -type f -print0 | xargs -0 sed -i \
                  -e "s|/usr/libexec/virtiofsd|${final.virtiofsd}/bin/virtiofsd|g"
              '';
            });

            # Thread the patched server through the remaining packages
            pve-ha-manager' = prev.pve-ha-manager.override { pve-qemu-server = pve-qemu-server'; };
            pve-manager' = prev.pve-manager.override { pve-ha-manager = pve-ha-manager'; };
            proxmox-ve' = prev.proxmox-ve.override {
              pve-qemu-server = pve-qemu-server';
              pve-ha-manager = pve-ha-manager';
              pve-manager = pve-manager';
            };
          in
          {
            pve-qemu-server = pve-qemu-server';
            pve-ha-manager = pve-ha-manager';
            pve-manager = pve-manager';
            proxmox-ve = proxmox-ve';
          }
        )
      ];

      services.proxmox-ve = {
        enable = true;
        ipAddress = lib.mkDefault "192.168.1.101";
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
