{
  inputs,
  self,
  config,
  ...
}:
let
  inherit (config.mySnippets) primaryHome;
in
{
  home-manager.users.${config.mySnippets.primaryUser} =
    { config, lib, ... }:
    {
      imports = [
        self.homeModules.default
      ];

      myHome = {
        profiles.workstation.enable = true;

        desktop.darwin.aerospace.enable = true;
      };

      age.secrets.komodo-syncs-key = {
        file = "${inputs.secrets}/services/komodo/sync-keys/age-master.age";
        path = "${primaryHome}/.config/komodo/syncs-key.age";
        symlink = false;
      };

      # docker daemon without docker desktop
      services.colima = {
        enable = true;

        colimaHomeDir = "${config.xdg.configHome}/colima";

        limaHomeDir = ".lima";
      };

      home.activation.limaSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ln -sfn "/Volumes/Virtual Machines/lima" "$HOME/.lima"
      '';
    };
}
