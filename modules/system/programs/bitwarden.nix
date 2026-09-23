{
  flake.modules.hjem.bitwarden =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    in
    {
      packages =
        with pkgs;
        lib.optionals (!isDarwin) [
          bitwarden-desktop
        ];

      environment.sessionVariables = {
        SSH_AUTH_SOCK =
          if isDarwin then
            "${config.directory}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
          else
            "${config.directory}/.bitwarden-ssh-agent.sock";
      };
    };
}
