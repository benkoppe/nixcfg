{ self, inputs, ... }:
{
  flake.modules.nixos.ben = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager.users.ben = {
      imports = with self.modules.home; [ ben ];

      home.stateVersion = "25.05";
    };
  };

  flake.modules.home.ben = {
    imports = with self.modules.home; [
      git
      ssh
    ];
  };
}
