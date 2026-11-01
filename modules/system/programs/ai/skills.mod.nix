{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  flake.modules.hjem.skills =
    { config, ... }:
    let
      cfg = config.agents.skills;

      # Every subdirectory of `dir` that contains a SKILL.md, as name -> path.
      skillsIn =
        dir:
        lib.mapAttrs (name: _: "${dir}/${name}") (
          lib.filterAttrs (name: type: type == "directory" && builtins.pathExists "${dir}/${name}/SKILL.md") (
            builtins.readDir dir
          )
        );
    in
    {
      options.agents.skills = {
        entries = mkOption {
          type = types.attrsOf types.path;
          default = { };
          description = "Individual skills by name. Each value is a directory containing SKILL.md.";
        };
        sources = mkOption {
          type = types.listOf types.path;
          default = [ ];
          description = "Directories of skills. Every subdirectory containing SKILL.md becomes a skill.";
        };
        targets = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Directories, relative to home, that every skill is linked into.";
        };
        final = mkOption {
          type = types.attrsOf types.path;
          readOnly = true;
          description = "All skills after combining `sources` and `entries` (entries win).";
        };
      };

      config = {
        agents.skills.final = lib.foldl' (acc: dir: acc // skillsIn dir) { } cfg.sources // cfg.entries;

        agents.skills.targets = [ ".agents/skills" ];

        # One link per skill, so the target directories stay writable.
        files = lib.listToAttrs (
          lib.concatMap (
            target:
            lib.mapAttrsToList (name: path: lib.nameValuePair "${target}/${name}" { source = path; }) cfg.final
          ) (lib.unique cfg.targets)
        );
      };
    };
}
