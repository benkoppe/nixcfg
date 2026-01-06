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

    self.inputs.vgpu4nixos.nixosModules.host

    ./microvms.nix
  ];

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

  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.open = false;

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
