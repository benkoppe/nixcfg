{ self, inputs, ... }:
{
  flake.modules.nixos.ben = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager.users.ben = {
      imports = with self.modules.homeManager; [ ben ];

      home.stateVersion = "25.05";
    };
  };

  flake.modules.homeManager.ben = {
    imports = with self.modules.homeManager; [
      ben_git
      ben_ssh
    ];
  };
}
