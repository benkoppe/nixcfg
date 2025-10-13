{ self, config, ... }:
{
  home-manager.users.${config.myDarwin.primaryUser} = {
    imports = [
      self.homeModules.ben
    ];

    home.stateVersion = "25.05";
  };
}
