{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.myHome.programs.defaultbrowser = {
    enable = lib.mkEnableOption "use Aerospace for macOS window management";
    browser = lib.mkOption {
      type = lib.types.str;
      default = "browser"; # For some reason, brave registers as 'browser'
      description = "name of the default browser to set";
    };
  };

  config = lib.mkIf config.myHome.programs.defaultbrowser.enable {
    home.packages = [ pkgs.defaultbrowser ];

    home.activation = {
      setBrowser = lib.hm.dag.entryAfter [ "installPackages" ] ''
        run ${pkgs.defaultbrowser}/bin/defaultbrowser ${config.myHome.programs.defaultbrowser.browser}
      '';
    };
  };
}
