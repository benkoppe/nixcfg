{ self, ... }:
{
  flake.modules.nixos.profiles_butler =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.networking) hostName;

      butlerHosts = lib.filter (name: lib.hasPrefix "butler-" name) (
        lib.attrNames self.clan.inventory.machines
      );

      peerButlerHosts = lib.filter (name: name != hostName) butlerHosts;

      peerButlerAuthorizedKeys = map (
        name: builtins.readFile "${self}/vars/per-machine/${name}/ben-butler-ssh/id_ed25519.pub/value"
      ) peerButlerHosts;
    in
    {
      imports = with self.modules.nixos; [
        basics

        hjem
        niri
      ];

      hjem.users.ben = {
        user = "ben";
        directory = "/home/ben";

        imports = with self.modules.hjem; [
          profiles_butler
        ];
      };

      clan.core.vars.generators.ben-butler-ssh = {
        files."id_ed25519" = {
          secret = true;
          owner = "ben";
          mode = "0600";
        };
        files."id_ed25519.pub" = {
          secret = false;
          owner = "ben";
          mode = "0644";
        };
        runtimeInputs = [ pkgs.openssh ];
        script = ''
          ssh-keygen -t ed25519 -N "" -C "ben@${hostName}" -f "$out"/id_ed25519
        '';
      };

      users.users.ben.openssh.authorizedKeys.keys = peerButlerAuthorizedKeys;
    };

  flake.modules.hjem.profiles_butler = {
    imports = with self.modules.hjem; [
      niri
      browsers
      ssh
    ];
  };
}
