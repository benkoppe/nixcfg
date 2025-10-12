{ self, ... }:
{
  home-manager.users.ben =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [
        self.homeModules.ben
        self.inputs.agenix.homeManagerModules.default
      ];

      home.stateVersion = "25.05";
    };
}
