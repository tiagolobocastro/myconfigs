{ config, lib, pkgs, ... }: {
  # lxd should be enabled...
  systemd.services.lxd.path = with pkgs; [ lvm2 thin-provisioning-tools e2fsprogs ];

  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "eurosign:e"; # what's this for??

  services.iscsid.enable = true;
  services.flatpak.enable = false;
  #xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-kde ];
}
