{
  config,
  lib,
  self,
  pkgs,
  ...
}:
{
  options.myDarwin.programs.browsers.enable = lib.mkEnableOption "download browsers with homebrew";

  config = lib.mkIf config.myDarwin.programs.browsers.enable {
    homebrew.casks =
      let
        greedy = name: {
          inherit name;
          greedy = true;
        };
      in
      [
        (greedy "google-chrome")
        (greedy "brave-browser")
      ];

    home-manager.sharedModules = [
      {
        programs.firefox = {
          enable = true;

          package = self.inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.firefox;
        };
      }
    ];
  };
}
