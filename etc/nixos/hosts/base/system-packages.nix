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
    eza
    direnv

    # Monitoring
    htop
    inxi
    lm_sensors
    pciutils
  ];

  programs.nix-ld.enable = true;
}
