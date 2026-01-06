{ self, ... }:
{
  flake.clan.machines.vm-kde =
    { pkgs, config, ... }:
    {
      imports = [
        self.inputs.vgpu4nixos.nixosModules.guest

        self.inputs.nixos-generators.nixosModules.all-formats
        self.inputs.nixos-generators.nixosModules.qcow-efi
      ];

      # ----------- VM CLIENT -------------

      system.stateVersion = "26.05";

      nixpkgs.hostPlatform = "x86_64-linux";

      users.users.root.openssh.authorizedKeys.keys = [
        (builtins.readFile "${self}/vars/per-machine/dray/openssh/ssh.id_ed25519.pub/value")
      ];

      services.openssh = {
        settings = {
          PermitRootLogin = "prohibit-password";
          PermitEmptyPasswords = false;
          PasswordAuthentication = false;
        };
      };

      # ---------------------------------

      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;
      services.desktopManager.plasma6.enable = true;
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        khelpcenter
        krdp
      ];

      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.grid_16_5;

      boot.kernelPackages = pkgs.linuxPackages_6_6;
    };
}
