{
  flake.modules.nixos.boot_plymouth = {
    boot = {
      plymouth = {
        enable = true;
        theme = "bgrt";
      };

      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "splash"
        "udev.log_level=3"
        "rd.systemd.show_status=auto"
      ];
    };
  };
}
