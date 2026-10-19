{
  flake.modules.hjem.ssh =
    { lib, config, ... }:
    {
      files.".ssh/config".text =
        # sshclientconfig
        ''
          Include ${config.xdg.config.directory}/ssh/config
        '';

      xdg.config.files."ssh/config".text = lib.concatLines [
        # sshclientconfig
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
            SetEnv COLORTERM=truecolor

            ControlMaster auto
            ControlPersist 60m
            ControlPath ${config.xdg.cache.directory}/ssh/%r@%n:%p
        ''
      ];

      xdg.cache.files."ssh" = {
        type = "directory";
        clobber = false;
      };
    };
}
