{
  self,
  config,
  ...
}:
{
  home-manager.users.${config.mySnippets.primaryUser} = {
    imports = [
      self.homeModules.default
    ];

    myHome = {
      profiles.workstation.enable = true;

      desktop.darwin.aerospace.enable = true;
    };
  };
}
