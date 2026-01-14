{ self, lib, ... }:
{
  flake.modules.nixos."microvms_client" = {
    imports = with self.modules.nixos; [
      basics

      microvms_client_network
      microvms_client_vsock-ssh

      microvms_client_nix-store-read
      microvms_client_nix-store-write

      self.inputs.microvm.nixosModules.microvm
    ];

    options.my.microvm = {
      id = lib.mkOption {
        type = lib.types.int;
        description = "VM's unique identifier, used for networking";
      };
    };

    config = {
      system.stateVersion = "26.05";

      nixpkgs.hostPlatform = "x86_64-linux";

      clan.core.deployment.requireExplicitUpdate = true;

      # see https://git.clan.lol/clan/clan-core/src/commit/ca83bb80c2ded7fe6f3a26216e62d35aa3158a59/nixosModules/clanCore/zfs.nix
      # this resolves conflict between microvm.nix and zfs.nix
      networking.hostId = "8425e349";

      # fix problems where microvms would start pulling 'stale file handle' errors
      # from the virtiofs mounts after running for ~12 hours
      microvm.virtiofsd.inodeFileHandles = "never";

      # chatgpt said this might help with the above virtiofs issue
      # fileSystems."/etc" = {
      #   fsType = "tmpfs";
      #   device = "tmpfs";
      #   options = [ "mode=0755" ];
      # };

      nix.optimise.automatic = lib.mkForce false;
      nix.gc.automatic = lib.mkForce false;

      # persistent systemctl logs
      microvm.volumes = [
        {
          image = "log.img";
          mountPoint = "/var/log";
          size = 1024; # 1 GiB
        }
        {
          image = "systemd-timers.img";
          mountPoint = "/var/lib/systemd/timers";
          size = 256; # 256 MiB
        }
        {
          image = "systemd-coredump.img";
          mountPoint = "/var/lib/systemd/coredump";
          size = 512; # 512 MiB
        }
      ];
    };
  };
}
