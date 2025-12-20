{
  self,
  modulesPath,
  ...
}:
{
  imports = [
    self.diskoConfigurations.simple-ext4
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  myNixOS = {
    profiles.server.enable = true;
  };

  services.cloud-init.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  nixpkgs.hostPlatform = "aarch64-linux";

  # from hardware config
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "usbhid"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };
}
