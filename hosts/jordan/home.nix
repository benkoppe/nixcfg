{ self, config, ... }:
{
  home-manager.users.${config.mySnippets.primaryUser} = {
    imports = [
      self.homeModules.ben
    ];

    home.stateVersion = "25.05";
  };
}
