{
  flake.modules.hjem.ssh =
    { lib, config, ... }:
    {
      xdg.config.files."ssh/config".text = lib.concatLines [
        ''
          Host *
            Compression no
            ForwardAgent no
            AddKeysToAgent yes

            ServerAliveInterval 60
            ServerAliveCountMax 3

            HashKnownHosts no
            UserKnownHostsFile ~/.ssh/known_hosts

            User root
            SetEnv COLORTERM=truecolor TERM=xterm-256color

            ControlMaster auto
            ControlPersist 60m
            ControlPath ${config.xdg.cache.directory}/ssh/%r@%n:%p
        ''
      ];
    };
}
