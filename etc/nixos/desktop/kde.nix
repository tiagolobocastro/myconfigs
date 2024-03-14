{ config, pkgs, lib, ... }:
{
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Enable the KDE Desktop Environment
  services.xserver.desktopManager.plasma5.enable = true;
  #services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

  # Browser Plasma Integration
  programs.firefox.nativeMessagingHosts.packages = [ pkgs.plasma5Packages.plasma-browser-integration ];

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
    # p3x-onenote
  ];
}
