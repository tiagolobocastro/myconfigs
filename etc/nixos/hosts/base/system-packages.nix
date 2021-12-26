{ config, lib, pkgs, ... }: {
  # Base Programs for all host's
  environment.systemPackages = with pkgs; [
    # Basic
    wget
    git
    nixpkgs-fmt
    manpages
    unzip
    tree
    exa

    # Sync Data 
    #onedrive

    #ntfs3g
  ];
  #services.onedrive.enable = false;
}
