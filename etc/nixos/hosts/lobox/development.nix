{ config, lib, pkgs, ... }:
let unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  # Containers and virtual machines
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    lxd = { enable = true; };
    docker = {
      enable = true;
      extraOptions = ''
        --insecure-registry 192.168.1.137:5000
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    # GUIs
    drawio

    # Container development
    lxd
    thin-provisioning-tools
    lvm2
    e2fsprogs

    # Kubernetes    
    unstable.terraform-full
    ansible
    virt-manager
    kubectl
    k9s

    # Golang
    jetbrains.goland
    go
    pkg-config
    alsaLib
    gopls

    # DBG
    linuxPackages.bpftrace

    # Java
    jdk11

    # Networking
    tcpdump
    wireshark

    zerotierone
    cntr
    direnv
  ];

  services.zerotierone = { enable = false; };
}
