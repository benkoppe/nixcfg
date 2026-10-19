{ inputs, self, ... }:
{
  flake.modules.generic.hjem = {
    hjem.extraModules = [
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
    { config, lib, ... }:
    {
      imports = [
        inputs.hjem-rum.hjemModules.hjem-rum
      ];

      # Shell-agnostic aliases
      options.shellAliases = lib.mkOption {
        type =
          let
            inherit (lib) types;
          in
          types.attrsOf types.str;

        default = { };
        description = "Aliases defined in every POSIX-like shell hjem manages.";
      };

      options.shellAliasesInit = lib.mkOption {
        type = lib.types.lines;
        readOnly = true;
        internal = true;
        default = lib.concatMapAttrsStringSep "\n" (
          name: value: "alias -- ${lib.escapeShellArg name}=${lib.escapeShellArg value}"
        ) config.shellAliases;
      };

      config = {
        shellAliases.":q" = "exit";

        clobberFiles = true;

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
    };
}
