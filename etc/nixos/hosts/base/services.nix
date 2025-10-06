{ config, lib, pkgs, ... }: {
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    xkb = {
      options = "intl";
      #options = "eurosign:e"; # what's this for??
      layout = "us";
    };
  };

  #services.flatpak.enable = true;
  #xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-kde ];
}
