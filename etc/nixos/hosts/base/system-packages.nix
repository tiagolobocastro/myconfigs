{ config, lib, pkgs, ... }: {
  # Base Programs for all host's
  environment.systemPackages = with pkgs; [
    # Basic
    wget
    git
    nixpkgs-fmt
    man-pages
    unzip
    tree
    exa

    # Sync Data 
    #onedrive

    #ntfs3g

    # Monitoring
    htop
    inxi
    lm_sensors
    pciutils
  ];
  #services.onedrive.enable = false;
}
