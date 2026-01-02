{ lib, self, ... }:
{
  flake.modules.nixos.basics = {
    imports = with self.modules.nixos; [ nix ];

    time.timeZone = lib.mkDefault "America/Los_Angeles";

    programs.bash.shellAliases = {
      ":q" = "exit";
    };
  };
}
