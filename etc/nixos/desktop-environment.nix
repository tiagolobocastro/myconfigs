{ config, lib, pkgs, ... }: 
let
  mine = import /home/tiago/git/nixpkgs { config = config.nixpkgs.config; };
in
{
  # Enable the KDE Desktop Environment
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Browser Plasma Integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # NVIDIA drivers
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Desktop Apps
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox-bin chromium

    # Office
    mine.p3x-onenote

    # Kde specific
    kate kcalc spectacle yakuake ark partition-manager kdesu

    # Monitoring
    htop inxi lm_sensors pciutils

    # Misc
    keepass terminator gparted
  ];
}
