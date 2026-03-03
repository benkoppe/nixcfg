{ self, inputs, ... }:
{
  flake.modules.nixos.ben = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager.users.ben = {
      imports = with self.modules.home; [ ben ];
    };
  };

  flake.modules.home.ben = {
    imports = with self.modules.home; [
      git
      ssh
    ];
  };
}
