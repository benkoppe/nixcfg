{ self, inputs, ... }:
{
  flake.modules.nixos.rex =
    { config, ... }:
    {
      imports = [ inputs.rex.nixosModules.default ];

      hjem.extraModules = with self.modules.hjem; [ rex ];

      clan.core.vars.generators.rex-tailscale-auth-key = {
        prompts.key.persist = true;
        share = true;
      };

      services.tailscale = {
        enable = true;
        authKeyFile = config.clan.core.vars.generators.rex-tailscale-auth-key.files.key.path;
        extraSetFlags = [ "--accept-routes=false" ];
      };

      services.rex.loginServer =
        let
          me = "tailscale:benkoppe@github";
          # tagged devices, like ant, never match a user login
          adminDevices = "tailscale:tag:admin-personal-device";
        in
        {
          enable = true;

          accounts.ben.principals = [
            me
            adminDevices
          ];
          defaults = {
            ${me} = "ben";
            ${adminDevices} = "ben";
          };

          tailscaleServe.enable = true;
        };
    };

  flake.modules.hjem.rex =
    { pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin system;
      rexPackage = inputs.rex.packages.${system}.rex;

      # On macOS the Rex app runs the server, so use the CLI it bundles to keep versions matched.
      rexCli =
        if isDarwin then
          pkgs.writeShellScriptBin "rex" ''
            exec "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex" "$@"
          ''
        else
          rexPackage;

      # The stub skill `rex skill setup` writes. It asks the installed rex for its guide at runtime.
      rexSkill = pkgs.runCommand "rex-skill" { } ''
        export HOME=$TMPDIR/home
        ${rexPackage}/bin/rex skill setup --agent opencode --autostart=false >/dev/null
        cp -r $HOME/.agents/skills/rex $out
      '';
    in
    {
      imports = with self.modules.hjem; [
        ai-setup
        rex-agent-resume
      ];

      packages = [ rexCli ];

      agents = {
        skills.entries.rex = rexSkill;
        mcp.servers.superlogical.url = "https://www.superlogical.com/rex/community-mcp";
      };
    };
}
