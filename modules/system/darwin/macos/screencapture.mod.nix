{
  flake.modules.darwin.screencapture = {
    system.defaults.screencapture = {
      location = "~/Downloads";

      include-date = true;
    };
  };
}
