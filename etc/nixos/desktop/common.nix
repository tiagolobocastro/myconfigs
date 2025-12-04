{ config, pkgs, lib, ... }:
{
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Desktop Apps
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox-bin
    chromium
    brave

    # Misc
    terminator
    gparted

    # Passwords
    bitwarden-desktop
  ];
}
