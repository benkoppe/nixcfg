{ self, ... }:
{
  flake.modules.nixos.profiles_butler = {
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
  };

  flake.modules.hjem.profiles_butler = {
    imports = with self.modules.hjem; [
      niri
      browsers
      ssh
    ];
  };
}
