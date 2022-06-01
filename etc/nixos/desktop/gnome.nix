{ config, pkgs, lib, ... }: {
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Enable the Gnome Desktop Environment
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Browser Plasma Integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # Desktop Apps
  environment.systemPackages = with pkgs; [
    # Kde specific
    kate
    kcalc
    spectacle
    yakuake
    ark
    partition-manager

    # Office
    #p3x-onenote
  ];
}
