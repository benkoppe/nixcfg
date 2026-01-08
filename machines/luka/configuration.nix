{
  self,
  pkgs,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    luks-encrypt
    self.inputs.nixos-vfio.nixosModules.vfio
    proxmox

    ./microvms.nix
  ];

  my.proxmox.id = 2;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
    krdp
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    sshProxy = false;
    qemu.swtpm.enable = true;
    deviceACL = [
      "/dev/kvm"
      "/dev/kvmfr0"
      "/dev/kvmfr1"
      "/dev/kvmfr2"
      "/dev/shm/scream"
      "/dev/shm/looking-glass"
      "/dev/null"
      "/dev/full"
      "/dev/zero"
      "/dev/random"
      "/dev/urandom"
      "/dev/ptmx"
      "/dev/kvm"
      "/dev/kqemu"
      "/dev/rtc"
      "/dev/hpet"
      "/dev/vfio/vfio"
    ];
  };
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.vfio = {
    enable = true;
    IOMMUType = "amd";
    devices = [
      "10de:2704" # RTX 4080
      "10de:22bb" # HDMI/DP audio
    ];
    blacklistNvidia = true;
    disableEFIfb = true;
  };
  # virtualisation.hugepages = {
  #   enable = true;
  #   pageSize = "1G";
  #   numPages = 16; # match guest RAM
  # };
  virtualisation.kvmfr = {
    enable = true;
    devices = [
      {
        size = 128; # MB
        permissions = {
          user = "microvm";
          mode = "0777";
        };
      }
    ];
  };
  environment.systemPackages = with pkgs; [
    virtiofsd
    looking-glass-client
  ];
  services.udev.packages = with pkgs; [
    vial
    via
  ];
}
