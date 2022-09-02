{ config, pkgs, lib, ... }: 
# let
#   unstable = import <nixgit> { config = config.nixpkgs.config; };
# in
{
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Enable the KDE Desktop Environment
  services.xserver.desktopManager.plasma5.enable = true;
  #services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

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
    # unstable.p3x-onenote
  ];
}
