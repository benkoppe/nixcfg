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

          ncps = {
            module.name = "ncps";
            roles.server.settings = {
              dataPath = "/var/lib/ncps";
              caches = [
                "https://cache.thekoppe.com"
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
                "https://cache.saumon.network/proxmox-nixos"
                "https://nixpkgs-unfree.cachix.org"
                "https://nix-gaming.cachix.org"
                "https://cuda-maintainers.cachix.org"
              ];
              publicKeys = [
                "cache.thekoppe.com-1:k6bpXbbySclfYx+w7EoTxq/R/mveWHpOe7daqtNsLA0="
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "proxmox-nixos:D9RYSWpQQC/msZUWphOY2I5RLH5Dd6yQcaHIuug7dWM="
                "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
                "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
                "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
              ];
            };
          };
        };
      };
    };
}
