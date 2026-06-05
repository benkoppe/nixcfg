{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDArwin;
in
{
  flake.modules.hjem.bitwarden = {
    environment.sessionVariables = {
      SSH_AUTH_SOCK = "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";
    };
  };
}
