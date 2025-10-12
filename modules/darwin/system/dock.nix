{
  config,
  lib,
  self,
  ...
}:
{
  options.myDarwin.system.dock.enable = lib.mkEnableOption "sensible dock defaults";

  config = lib.mkIf config.myDarwin.system.dock.enable {
    system.defaults.dock = {
      autohide = true;
      showhidden = true; # Translucent.
      orientation = "bottom";

      mouse-over-hilite-stack = true;

      show-recents = false;
      mru-spaces = false;

      tilesize = 48;
      magnification = false;

      enable-spring-load-actions-on-all-items = true;
      scroll-to-open = true;
    };

    system.defaults.CustomSystemPreferences."com.apple.dock" = {
      autohide-time-modifier = 0.0;
      autohide-delay = 0.01;
      expose-animation-duration = 0.0;
      springboard-show-duration = 0.0;
      springboard-hide-duration = 0.0;
      springboard-page-duration = 0.0;

      # Diable hot corners.
      wvous-tl-corner = 0;
      wvous-tr-corner = 0;
      wvous-bl-corner = 0;
      wvous-br-corner = 0;

      launchanim = 0;
    };
  };
}
