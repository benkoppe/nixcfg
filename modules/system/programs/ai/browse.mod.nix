{ self, ... }:
{
  # browse (https://opencode.ai/browse): agents drive your own browser through its extension.
  # Replaces `curl -fsSL https://opencode.ai/browse/install | bash`, which would copy the binary into
  # ~/.local/bin, self-update it, and edit the (nix-managed) agent configs. Pairing is still a one-time,
  # stateful step: add the extension from the Chrome Web Store, then run `browse pair`.
  flake.modules.hjem.browse =
    { pkgs, ... }:
    let
      browse = self.packages.${pkgs.stdenv.hostPlatform.system}.browse;

      browseSkill = pkgs.runCommand "browse-skill" { } ''
        export HOME=$TMPDIR/home OPENCODE_BROWSER_AUTO_UPDATE=off OPENCODE_BROWSER_AUTOSTART=0
        mkdir -p $out
        ${browse}/bin/browse skill > $out/SKILL.md
      '';
    in
    {
      imports = with self.modules.hjem; [ ai-setup ];

      packages = [ browse ];

      agents = {
        skills.entries.browse = browseSkill;
        mcp.servers.browse = {
          command = "${browse}/bin/browse";
          args = [ "mcp" ];
          # Updates come from bumping pkgs/browse, not the built-in updater.
          env.OPENCODE_BROWSER_AUTO_UPDATE = "off";
        };
      };
    };
}
