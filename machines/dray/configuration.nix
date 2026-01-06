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

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_17_3;

  hardware.nvidia.vgpu.patcher = {
    enable = true;
    copyVGPUProfiles = {
      "1B38:0000" = "1BB0:0000";
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
}
