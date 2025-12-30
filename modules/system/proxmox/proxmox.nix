{ inputs, lib, ... }:
{
  flake.modules.nixos.proxmox = {
    imports = [
      inputs.proxmox-nixos.nixosModules.proxmox-ve
    ];

    nixpkgs.overlays = [
      inputs.proxmox-nixos.overlays.x86_64-linux
    ];

    services.proxmox-ve = {
      enable = true;
      ipAddress = "192.168.1.217";
    };

    services.openssh = {
      settings.AcceptEnv = lib.mkForce [
        "LANG"
        "LC_*"
      ];
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
