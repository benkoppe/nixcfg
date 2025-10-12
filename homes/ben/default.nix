{
  config,
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
      programs.home-manager.enable = true;
      xdg.enable = true;

      myHome = {
        profiles.full.enable = true;
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
        homeDirectory = "/home/ben";
      };
    })
  ];
}
