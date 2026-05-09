{
  flake.modules.hjem.opencode =
    { lib, ... }:
    {
      xdg.config.files."opencode/opencode.json" = {
        generator = lib.generators.toJSON { };
        value = {
          "$schema" = "https://opencode.ai/config.json";
          plugin = [ "opencode-claude-auth@latest" ];
        };
      };
    };
}
