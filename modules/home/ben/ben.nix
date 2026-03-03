{ self, inputs, ... }:
{
  flake.modules.nixos.ben = {
    imports = with self.modules.nixos; [
      ben_git_secrets
      ben_ssh_secrets
      inputs.home-manager.nixosModules.home-manager
    ];

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
