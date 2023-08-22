{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pkg-config
    # DBG
    linuxPackages.bpftrace

    # Networking
    tcpdump

    #home-manager
  ];

  # home-manager.users.tiago = { pkgs, ... }: {
  #   home.packages = [ pkgs.atool pkgs.httpie ];
  #   programs.bash.enable = true;
  # };
  # home-manager.useGlobalPkgs = true;
}
