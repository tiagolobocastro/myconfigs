{ config, pkgs, lib, ... }: {
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Enable the KDE Desktop Environment
  services.xserver.desktopManager.plasma5.enable = true;

  # Browser Plasma Integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # Desktop Apps
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox-bin
    chromium
    brave

    # Misc
    terminator
    gparted
  ];
}
