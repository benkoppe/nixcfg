{ pkgs, ... }:
{
  services.desktopManager.plasma6 = {
    enable = true;
  };

  services.displayManager = {
    enable = true;
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;

    modesetting.enable = true;
    nvidiaSettings = true;

    powerManagement.enable = true;
  };

  # environment.systemPackages = with pkgs; [
  #   # kdePackages.konsole
  #   # kdePackages.dolphin
  #   # kdePackages.okular
  #   # kdePackages.gwenview
  #   # kdePackages.kate
  #   # kdePackages.kcalc
  #   # kdePackages.libksysguard
  #   # kdePackages.konversation
  #   # kdePackages.breeze-icons
  # ];

  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
  };

  # programs.firefox = {
  #   enable = true;
  # };
}
