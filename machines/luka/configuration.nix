{
  self,
  pkgs,
  ...
}:
{
  imports = with self.modules.nixos; [
    basics
    luks-encrypt
    # self.inputs.microvm.nixosModules.host
    # steam-microvm
  ];

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

  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"

    "amdgpu"
  ];

  boot.kernelParams = [
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
