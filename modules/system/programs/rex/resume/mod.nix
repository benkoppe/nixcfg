{
  # Resume via OSC 7577: plugins report, resume.lua decides what Rex trusts.
  flake.modules.hjem.rex-resume =
    { lib, ... }:
    {
      # Auto-discovered by opencode.
      xdg.config.files."opencode/plugins/rex-resume/tui.js".source = ./opencode-plugin/tui.js;

      # Before local.lua, so it can override the rules.
      xdg.config.files."rex/resume.lua".source = ./resume.lua;
      xdg.config.files."rex/init.lua".text = lib.mkBefore ''
        require("resume")
      '';
    };
}
