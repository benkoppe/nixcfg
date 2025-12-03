{
  config,
  pkgs,
  inputs,
  ...
}:
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;
  };

  virtualisation.docker = {
    enable = true;

    # enable ipv6 with docker
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "monolith";
      url = "https://git.thekoppe.com";
      # tokenFile should be in format TOKEN=<secret>, since it's EnvironmentFile for systemd
      tokenFile = config.age.secrets.forgejo-runner-token.path;
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
        "nix:docker://nixos/nix"
        ## optionally provide native execution on the host:
        # "native:host"
      ];
    };
  };

  age.secrets.forgejo-runner-token.file = "${inputs.secrets}/services/forgejo/runner-token.age";

  # add docker bridge interfaces to firewall to use docker runners with cache actions
  networking.firewall.trustedInterfaces = [ "br-+" ];
}
