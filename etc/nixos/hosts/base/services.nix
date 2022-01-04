{ config, lib, pkgs, ... }: {
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "eurosign:e"; # what's this for??

  #services.flatpak.enable = true;
  #xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-kde ];
}
