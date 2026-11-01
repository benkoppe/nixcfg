{ lib, ... }:
{
  flake.modules.hjem.mcp =
    { config, ... }:
    {
      config.assertions = lib.concatLists (
        lib.mapAttrsToList (name: server: [
          {
            assertion = (server.command != null) != (server.url != null);
            message = "agents.mcp.servers.${name}: set exactly one of `command` or `url`.";
          }
          {
            assertion = server.url == null || (server.args == [ ] && server.env == { });
            message = "agents.mcp.servers.${name}: `args` and `env` are only valid for local servers (`command`).";
          }
          {
            assertion = server.headers == { } || server.url != null;
            message = "agents.mcp.servers.${name}: `headers` is only valid for remote servers (`url`).";
          }
        ]) config.agents.mcp.servers
      );

      options.agents.mcp.servers = lib.mkOption {
        default = { };
        description = "MCP servers shared by all AI agent modules.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              command = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Executable for a local (stdio) server. Mutually exclusive with `url`.";
              };
              args = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Arguments passed to `command`.";
              };
              env = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Environment variables for a local server.";
              };
              url = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Endpoint for a remote (HTTP) server. Mutually exclusive with `command`.";
              };
              headers = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "HTTP headers sent to a remote server.";
              };
              enabled = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether agents should start this server.";
              };
            };
          }
        );
      };
    };
}
