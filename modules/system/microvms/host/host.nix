{ self, inputs, ... }:
{
  flake.modules.nixos."microvms_host" =
    { config, ... }:
    {
      imports = with self.modules.nixos; [
        inputs.microvm.nixosModules.host

        microvms_host_network
      ];

      programs.bash.interactiveShellInit = ''
        enter() {
          if [ -z "$1" ]; then
            echo "usage: enter <vm-name>" >&2
            return 1
          fi
          microvm -s "$1" -- -i ${config.clan.core.vars.generators.openssh.files."ssh.id_ed25519".path}
        }
      '';
    };
}
