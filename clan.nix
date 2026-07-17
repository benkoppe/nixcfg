{
  flake.clan =
    { self, ... }:
    {
      meta = {
        name = "infra";
        domain = "thekoppe.com";
        description = "Homelab";
      };

      inventory = {
        machines = {
          butler-fusion = {
            deploy.targetHost = "root@172.16.85.129";
            tags = [
              "development"
              "butler"
            ];
          };
          butler-proxmox = {
            deploy.targetHost = "root@10.0.1.29";
            tags = [
              "development"
              "butler"
            ];
          };
          luka = {
            deploy.targetHost = "root@luka";
            tags = [ "development" ];
          };
          bird.deploy.targetHost = "root@bird";
          dray = {
            deploy.targetHost = "root@dray";
            tags = [ "development" ];
          };
          shai = {
            deploy.targetHost = "root@shai";
            tags = [ "development" ];
          };

          ant = {
            machineClass = "darwin";
          };
        };

        instances = {
          sshd = {
            roles.server.tags.all = { };
            roles.server.settings = {
              authorizedKeys = {
                colmena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgiH4Iu1GUe9Hd40cSnQH94EHj0VmjXdbsaBED2WMHT colmena";
              };
              certificate.searchDomains = [ "thekoppe.com" ];
            };
          };

          user-root = {
            module.name = "users";
            roles.default.tags.all = { };
            roles.default.settings = {
              user = "root";
              prompt = false;
            };
          };

          user-ben-dev = {
            module.name = "users";

            roles.default.tags.development = { };
            roles.default.settings = {
              user = "ben";
              share = true;
              groups = [
                "wheel"
                "networkmanager"
                "video"
                "input"
              ];
            };
            roles.default.extraModules = with self.modules.nixos; [ development ];
          };

          user-nancy = {
            module.name = "users";
            roles.default.settings = {
              user = "nancy";
              share = true;
              groups = [
                "networkmanager"
                "video"
                "input"
              ];
            };
            roles.default.machines.magic = { };
            roles.default.extraModules = [
              {
                users.users.nancy.description = "Nancy";
              }
            ];
          };

          clan-cache = {
            module.name = "trusted-nix-caches";
            roles.default.tags.all = { };
            roles.default.extraModules = [ ];
          };

          # use dray as cache proxy
          ncps = {
            roles.server.machines."dray".settings = {
              dataPath = "/var/lib/ncps";
              caches = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
                "https://install.determinate.systems"
                "https://cache.saumon.network/proxmox-nixos"
                "https://nixpkgs-unfree.cachix.org"
                "https://nix-gaming.cachix.org"
                "https://cuda-maintainers.cachix.org"
              ];
              publicKeys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
                "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
                "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
                "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
                "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
              ];
            };

            roles.client.machines."luka".settings = { };
            roles.client.machines."shai".settings = { };
          };
        };
      };
    };
}
