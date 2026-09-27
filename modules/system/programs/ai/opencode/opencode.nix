{ inputs, ... }:
let
  commands.allowed = [
    "rg*"
    "ls*"

    "git blame*"
    "git branch*"
    "git check-ignore*"
    "git config --get*"
    "git config --list*"
    "git config --show-origin*"
    "git describe*"
    "git diff*"
    "git fetch*"
    "git for-each-ref*"
    "git grep*"
    "git help*"
    "git log*"
    "git ls-files*"
    "git ls-remote*"
    "git merge-base*"
    "git name-rev*"
    "git reflog*"
    "git remote*"
    "git rev-list*"
    "git rev-parse*"
    "git shortlog*"
    "git show*"
    "git sparse-checkout list*"
    "git stash list*"
    "git stash show*"
    "git status*"
    "git submodule status*"
    "git tag*"
    "git version*"
    "git worktree list*"

    "gh auth status*"
    "gh cache list*"
    "gh gist list*"
    "gh gist view*"
    "gh issue list*"
    "gh issue status*"
    "gh issue view*"
    "gh label list*"
    "gh pr checks*"
    "gh pr diff*"
    "gh pr list*"
    "gh pr status*"
    "gh pr view*"
    "gh release list*"
    "gh release view*"
    "gh repo list*"
    "gh repo view*"
    "gh ruleset check*"
    "gh ruleset list*"
    "gh ruleset view*"
    "gh run list*"
    "gh run view*"
    "gh search *"
    "gh status*"
    "gh variable get*"
    "gh variable list*"
    "gh workflow list*"
    "gh workflow view*"
  ];
in
{
  flake.modules.hjem.opencode =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      packages =
        let
          llm-agents = inputs.llm-agents.packages.${system};
        in
        [
          llm-agents.opencode
          llm-agents.opencode2
          llm-agents.cli-proxy-api
          (pkgs.callPackage ./_plannotator.nix { })
        ];

      xdg.config.files."opencode/skills".source = builtins.path {
        path = ./skills;
        name = "opencode-skills";
      };

      xdg.config.files."opencode/commands/plannotator-review.md".text = ''
        --- description: Open interactive code review for current changes or a PR URL; pass --git to force Git in JJ workspaces ---
      '';

      xdg.config.files."opencode/commands/plannotator-annotate.md".text = ''
        --- description: Open interactive annotation UI for a markdown file, HTML file, or URL ---
      '';

      xdg.config.files."opencode/commands/plannotator-last.md".text = ''
        --- description: Annotate the last assistant message ---
      '';

      xdg.config.files."opencode/opencode.json" = {
        generator = lib.generators.toJSON { };
        value = {
          "$schema" = "https://opencode.ai/config.json";

          autoupdate = false;

          plugin = [
            [
              "@plannotator/opencode@latest"
              {
                workflow = "manual";
              }
            ]
          ];

          permission = {
            "*" = "ask";
            codesearch = "allow";
            glob = "allow";
            grep = "allow";
            list = "allow";
            lsp = "allow";
            read = "allow";
            task = "allow";
            todoread = "allow";
            todowrite = "allow";
            webfetch = "allow";
            websearch = "allow";

            bash = lib.genAttrs commands.allowed (lib.const "allow");
          };

          lsp = true;

          provider.anthropic.settings = {
            baseURL = "http://localhost:8317";
            apiKey = "{env:OPENCODE_PROXY_API_KEY}";
          };
        };
      };
    };
}
