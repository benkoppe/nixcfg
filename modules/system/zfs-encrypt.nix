{
  flake.modules.nixos.luks-encrypt =
    { pkgs, config, ... }:
    {
      # options.my.luks.ethernetDriver

      clan.core.vars.generators.zfs-encrypt = {
        prompts.password = {
          description = "ZFS encryption password";
          type = "hidden";
          persist = true;
        };
        files.password.neededFor = "partitioning";
        prompts.initrd-password = {
          description = "ZFS password encrypted with clevis for initrd unlocking";
          type = "hidden";
          persist = true;
        };
        files.initrd-password.neededFor = "activation";
      };

      clan.core.vars.generators.initrd-ssh = {
        files."ssh_host_ed25519_key" = {
          secret = true;
          owner = "root";
          group = "root";
          mode = "0600";
        };
        files."ssh_host_ed25519_key.pub" = {
          secret = false;
        };
        runtimeInputs = [ pkgs.openssh ];
        script = ''ssh-keygen -t ed25519 -N "" -f $out/ssh_host_ed25519_key'';
      };

      boot.initrd = {
        clevis = {
          enable = true;
          useTang = true;
          devices.crypted.secretFile =
            config.clan.core.vars.generators.zfs-encrypt.files.initrd-password.path;
        };

        availableKernelModules = [
          "xhci_pci" # taken from clan guide for ssh
        ]
        # add ethernet driver module for tang
        ++ config.hardware.facter.detected.boot.initrd.networking.kernelModules;

        systemd = {
          enable = true;
          network.enable = true;
        };

        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 7777;
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgiH4Iu1GUe9Hd40cSnQH94EHj0VmjXdbsaBED2WMHT colmena"
            ];
            hostKeys = [
              config.clan.core.vars.generators.initrd-ssh.files."ssh_host_ed25519_key".path
            ];
          };
        };

      };

      boot.kernelParams = [
        "ip=dhcp" # internet for tang
      ];
    };
}
