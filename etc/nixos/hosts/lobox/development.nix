{ config, lib, pkgs, ... }:
let unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  environment.systemPackages = with pkgs; [
    # GUIs
    drawio

    # Golang
    jetbrains.goland
    go
    pkg-config
    alsaLib
    gopls

    # DBG
    linuxPackages.bpftrace

    # Networking
    tcpdump
    wireshark

    # zerotierone
    cntr

    unstable.zoom
  ];

  services.zerotierone = { enable = true; };
}
