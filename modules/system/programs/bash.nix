{
  flake.modules.hjem.bash =
    { config, ... }:
    {
      files.".bashrc".text = ''
        ${config.environment.loadEnv}
      '';

      files.".bash_profile".text = ''
        if [ -f "$HOME/.bashrc" ]; then
          . "$HOME/.bashrc"
        fi
      '';
    };
}
