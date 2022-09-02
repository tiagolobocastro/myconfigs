{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  # Why?
  nixpkgs.config.allowUnfree = true;

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

    # Passwords
    bitwarden
  ];
}
