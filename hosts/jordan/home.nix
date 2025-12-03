{ self, config, ... }:
{
  home-manager.users.${config.mySnippets.primaryUser} = {
    imports = [
      self.homeModules.default
    ];

    myHome = {
      profiles.full.enable = true;
      profiles.gaming.enable = true;

      desktop.darwin.aerospace.enable = true;
      programs.defaultbrowser.enable = true;
    };
  };
}
