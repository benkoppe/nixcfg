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
      settings = {
        Autologin = {
          Session = "plasma.desktop";
          User = "russ";
        };
      };
    };
  };

  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    # kdePackages.konsole
    # kdePackages.dolphin
    # kdePackages.okular
    # kdePackages.gwenview
    # kdePackages.kate
    # kdePackages.kcalc
    # kdePackages.libksysguard
    # kdePackages.konversation
    # kdePackages.breeze-icons
    chromium
  ];
}
