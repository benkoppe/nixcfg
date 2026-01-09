{
  self,
  pkgs,
  config,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    zfs-encrypt
    proxmox
    tailgate

    self.inputs.vgpu4nixos.nixosModules.host
    # self.inputs.nixos-vfio.nixosModules.vfio

    ./microvms.nix
  ];

  my.tailgate.routes = [
    "10.1.0.0/24"
    "10.1.1.0/24"
  ];

  programs.ssh.startAgent = true;

  clan.core.vars.generators.zfs-encrypt-tank0 = {
    files.password = {
      secret = true;
      neededFor = "partitioning";
    };
    script = ''
      openssl rand -hex 48 > $out/password
    '';
    runtimeInputs = with pkgs; [
      openssl
    ];
  };

  users.users.ben.extraGroups = [ "libvirtd" ];
  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  my.proxmox = {
    id = 1;
    network = {
      subnet = "10.1.1";
      externalInterface = "eno1";
    };
  };

  services.proxmox-ve = {
    enable = true;
    ipAddress = "192.168.1.24";
  };

  # hardware.graphics.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];
  #
  # services.xserver.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = true;
  # environment.plasma6.excludePackages = with pkgs.kdePackages; [
  #   elisa
  #   khelpcenter
  #   krdp
  # ];

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_16_5;

  hardware.nvidia.vgpu.patcher = {
    enable = true;
    copyVGPUProfiles = {
      "1BB0:0000" = "1B38:0";
    };
    profileOverrides = {
      # nvidia-49
      #   Available instances: 6
      #   Device API: vfio-pci
      #   Name: GRID P40-4Q
      #   Description: num_heads=4, frl_config=60, framebuffer=4096M, max_resolution=7680x4320, max_instance=6
      "49" = {
        heads = 1;
        enableCuda = true;
        display.width = 1920;
        display.height = 1080;
        framerateLimit = 144;
        xmlConfig = {
          vgpu_type = "NVS";
        };
      };
    };
  };

  # virtualisation.vfio = {
  #   enable = true;
  #   IOMMUType = "intel";
  #   devices = [
  #     "10de:1bb0" # Quadro P5000 GPU
  #     "10de:10f0" # HDMI/DP audio
  #   ];
  #   # blacklistNvidia = true;
  #   # disableEFIfb = true;
  # };
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"

    "nvidia" # replace or remove with your device's driver as needed
  ];
  boot.kernelParams = [
    "intel_iommu=on"
    "vfio-pci.ids=10de:1bb0,10de:10f0"
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    stable = import self.inputs.nixpkgs-stable {
      inherit (config.nixpkgs) config;
      inherit (pkgs) system;
      overlays = [
        config.boot.kernelPackages.nvidiaPackages.vgpuNixpkgsOverlay
      ];
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_6_6;

  programs.mdevctl.enable = true;
}
