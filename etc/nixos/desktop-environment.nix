{ config, pkgs, lib, ... }: 
let
  hostName = lib.removeSuffix "\n" (builtins.readFile ./hostname);
  hostNixPath = (./. + "/${hostName}");
in
{
  imports = [ (hostNixPath + "/extra-development.nix") ];

  nixpkgs.config.allowUnfree = true;

  # Enable the KDE Desktop Environment
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Browser Plasma Integration
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # Desktop Apps
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox-bin chromium brave

    # Office
    #p3x-onenote

    # Kde specific
    kate kcalc spectacle yakuake ark partition-manager

    # Monitoring
    htop inxi lm_sensors pciutils

    # Misc
    terminator gparted
  ];
}
