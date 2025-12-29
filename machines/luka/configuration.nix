{
  self,
  pkgs,
  config,
  ...
}:
{
  imports = with self.modules.nixos; [
    nix
    self.inputs.microvm.nixosModules.host
    steam-microvm
  ];

  clan.core.vars.generators.luks-password = {
    prompts.password = {
      description = "LUKS password for machine luka";
      type = "hidden";
    };
    files.password = {
      secret = true;
      neededFor = "partitioning";
    };
    prompts.initrd-password = {
      description = "LUKS password encrypted with clevis for initrd unlocking";
      type = "hidden";
    };
    files.initrd-password = {
      secret = true;
      neededFor = "activation";
    };
    script = ''
      cp $prompts/password $out/password
      cp $prompts/initrd-password $out/initrd-password
    '';
  };

  clan.core.vars.generators.initrd-ssh = {
    files."ssh_host_ed25519_key" = {
      secret = true;
      owner = "root";
      group = "root";
      mode = "0600";
    };
    files."ssh_host_ed25519_key.pub" = {
      secret = false;
    };
    runtimeInputs = [ pkgs.openssh ];
    script = ''ssh-keygen -t ed25519 -N "" -f $out/ssh_host_ed25519_key'';
  };

  boot.initrd = {
    clevis = {
      enable = true;
      useTang = true;
      devices.crypted.secretFile =
        config.clan.core.vars.generators.luks-password.files.initrd-password.path;
    };

    availableKernelModules = [
      "r8169" # add ethernet driver module for tang
      "xhci_pci" # taken from clan guide for ssh
    ];

    systemd = {
      enable = true;
      network.enable = true;
    };

    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 7777;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgiH4Iu1GUe9Hd40cSnQH94EHj0VmjXdbsaBED2WMHT colmena"
        ];
        hostKeys = [
          config.clan.core.vars.generators.initrd-ssh.files."ssh_host_ed25519_key".path
        ];
      };
    };

    kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"

      "amdgpu"
    ];
  };

  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true;
  # };
  # services.xserver = {
  #   enable = true;
  #   desktopManager = {
  #     xterm.enable = true;
  #     xfce.enable = true;
  #   };
  # };
  # services.displayManager.sddm.enable = true;
  # services.displayManager.defaultSession = "xfce";
  # services.xserver.videoDrivers = [ "amdgpu" ];

  boot.kernelParams = [
    "ip=dhcp" # internet for tang

    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:2704,10de:22bb" # ensure vfio claims the 4080
  ];
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
  ];
}
