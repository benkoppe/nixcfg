{
  flake.modules.hjem.bitwarden =
    { pkgs, lib, ... }:
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
            "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
          else
            "$HOME/.bitwarden-ssh-agent.sock";
      };
    };
}
