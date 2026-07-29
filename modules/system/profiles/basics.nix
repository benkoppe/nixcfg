{ lib, self, ... }:
{
  flake.modules.generic.basics = {
    environment.shellAliases = {
      ":q" = "exit";
    };
  };

  flake.modules.nixos.basics =
    { pkgs, ... }:
    {
      imports =
        (with self.modules.generic; [ basics ])
        ++ (with self.modules.nixos; [
          nix
          topology

          network_lan
        ]);

      # add system.primaryUser option to match with nix-darwin
      options = {
        system.primaryUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = {
        time.timeZone = lib.mkDefault "America/Los_Angeles";

        # I don't want the gnome ssh agent
        # when I want one, it's the one in bitwarden.nix
        services.gnome.gcr-ssh-agent.enable = false;

        environment.systemPackages = [ pkgs.ghostty.terminfo ];

        zramSwap = {
          enable = true;
          algorithm = "zstd";
        };
      };
    };

  flake.modules.darwin.basics = {
    imports = (with self.modules.generic; [ basics ]) ++ (with self.modules.darwin; [ nix ]);
  };

  flake.modules.hjem.basics = {
    imports = with self.modules.hjem; [
      ssh
      bash
    ];
  };
}
