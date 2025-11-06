{ pkgs, ... }:
{
  system = {
    defaults = {
      dock.persistent-apps = [
        {
          spacer = {
            small = false;
          };
        }
        { app = "/Applications/Brave Browser.app"; }
        { app = "${pkgs.spotify}/Applications/Spotify.app"; }
        { app = "/Applications/Discord.app"; }
        {
          spacer = {
            small = false;
          };
        }
        #{ app = "Users/ben/Applications/Home Manager Apps/Ghostty.app"; }
        { app = "${pkgs.ghostty-bin}/Applications/Ghostty.app"; }
        { app = "/Applications/Xcode.app"; }
        {
          spacer = {
            small = false;
          };
        }
      ];
    };
  };
}
