{ self, config, ... }:
{
  home-manager.users.${config.mySnippets.primaryUser} = {
    imports = [
      self.homeModules.default
    ];

    myHome = {
      profiles.base.enable = true;
    };
  };
}
