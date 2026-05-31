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
      imports = (with self.modules.generic; [ basics ]) ++ (with self.modules.nixos; [ nix ]);

      time.timeZone = lib.mkDefault "America/Los_Angeles";

      environment.systemPackages = [ pkgs.ghostty.terminfo ];
    };

  flake.modules.darwin.basics = {
    imports = (with self.modules.generic; [ basics ]) ++ (with self.modules.darwin; [ nix ]);
  };
}
