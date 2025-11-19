{
  pkgs,
  lib,
  self,
  ...
}:
{
  imports = [
    self.homeModules.default
  ];

  config = lib.mkMerge [
    {
      myHome = {
        profiles.full.enable = true;
        profiles.gaming.enable = true;
      };
    }

    (lib.mkIf pkgs.stdenv.isDarwin {
      home = {
        enableNixpkgsReleaseCheck = false;
        homeDirectory = "/Users/ben";
      };

      myHome = {
        desktop.darwin.aerospace.enable = true;
        programs = {
          defaultbrowser.enable = true;
        };
      };
    })

    (lib.mkIf pkgs.stdenv.isLinux {
      home = {
        homeDirectory = lib.mkDefault "/home/ben";
      };
    })
  ];
}
