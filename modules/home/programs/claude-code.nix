{
  config,
  lib,
  ...
}:
{
  options.myHome.programs.claude-code.enable = lib.mkEnableOption "claude code";

  config = lib.mkIf config.myHome.programs.claude-code.enable {
    programs.claude-code = {
      enable = true;

      settings = {
        includeCoAuthoredBy = false;

        allow = [
          "Bash(git diff:*)"
          "Edit"
        ];
        ask = [
          "Bash(git push:*)"
        ];
        defaultMode = "acceptEdits";
        deny = [
          "Read(./.env)"
          "Read(./secrets/**)"
        ];
      };
    };
  };
}
