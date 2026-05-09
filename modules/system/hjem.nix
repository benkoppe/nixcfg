{ inputs, self, ... }:
{
  flake.modules.generic.hjem = {
    hjem.extraModules = [
      inputs.hjem-rum.hjemModules.hjem-rum
      self.modules.hjem.hjem
    ];
  };

  flake.modules.darwin.hjem = {
    imports = [
      inputs.hjem.darwinModules.default
      self.modules.generic.hjem
    ];
  };

  flake.modules.nixos.hjem = {
    imports = [
      inputs.hjem.nixosModules.default
      self.modules.generic.hjem
    ];
  };

  flake.modules.hjem.hjem =
    { config, ... }:
    {
      # FORCE XDG ENV VARS
      # hjem only exports XDG_*_HOME when config value != option default.
      # The defaults do not match platform realities and setting the Linux
      # defaults here causes env vars to not be set. Setting them directly
      # bypasses hjem's conditional logic.
      environment.sessionVariables = {
        XDG_CACHE_HOME = "${config.directory}/.cache";
        XDG_CONFIG_HOME = "${config.directory}/.config";
        XDG_DATA_HOME = "${config.directory}/.local/share";
        XDG_STATE_HOME = "${config.directory}/.local/state";
      };
    };
}
