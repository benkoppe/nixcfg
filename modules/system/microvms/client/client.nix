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

      # persistent systemctl logs
      microvm.volumes = [
        {
          image = "journal-data.img";
          mountPoint = "/var/log/journal";
          size = 1024; # 1 GiB
        }
      ];
    };
  };
}
