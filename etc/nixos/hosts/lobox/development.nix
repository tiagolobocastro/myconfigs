{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # GUIs
    # drawio

    # Golang
    # jetbrains.goland
    go
    pkg-config
    # alsaLib
    gopls

    # DBG
    linuxPackages.bpftrace

    # Networking
    #tcpdump
    #wireshark

    zerotierone
    cntr
  ];

  services.zerotierone = { enable = true; };
}
