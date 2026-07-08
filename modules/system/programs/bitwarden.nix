{
  flake.modules.nixos.bitwarden = {
    # needed to make bitwarden work currently due to EOL electron
    # TODO: remove me when github.com/NixOS/nixpkgs/issues/526914 is resolved
    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };

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
          # TODO: remove this too, see above
          (bitwarden-desktop.override { electron_39 = pkgs.electron_39-bin; })
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
