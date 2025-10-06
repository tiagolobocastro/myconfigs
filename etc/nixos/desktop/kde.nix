{ config, pkgs, lib, ... }:
{
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Enable the KDE Desktop Environment
  #services.xserver.desktopManager.plasma5.enable = false;
  #services.xserver.displayManager.sddm.enable = true;
  #services.xserver.displayManager.lightdm.enable = true;

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;

  services.displayManager.defaultSession = "plasmax11";

  #programs.hyprland = {
  #  enable = true;
  #  xwayland.enable = true;
  #};

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Browser Plasma Integration
  programs.firefox.nativeMessagingHosts.packages = [ pkgs.plasma6Packages.plasma-browser-integration ];

  # Desktop Apps
  environment.systemPackages = with pkgs.kdePackages; [
    # Kde specific
    kate
    kcalc
    spectacle
    yakuake
    ark
    partitionmanager
    pkgs.linuxPackages_latest.perf

    # Office
    # p3x-onenote

    #pkgs.kitty
    #pkgs.waybar
    #pkgs.dunst
    #pkgs.libnotify
    #pkgs.swww
    #pkgs.rofi-wayland
  ];

  #xdg.portal.enable = true;
  #xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
