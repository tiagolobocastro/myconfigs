{ config, lib, pkgs, ... }:
let
  # The Base
  base_imports = [ ./mayadata.nix ];
  # iSCSI
  iscsi_imports = [ ../modules/iscsid.nix ];
  unstable = import <nixpkgs-master> { config = config.nixpkgs.config; };
in
rec {
  environment.systemPackages = with pkgs; [
    # Kubernetes
    (terraform.withPlugins (p: [ p.libvirt p.null p.template p.lxd p.kubernetes p.helm ])) # deploy local cluster via terraform
    ansible_2_10 # Otherwise we hit some python issues...
    virt-manager

    # DBG
    linuxPackages.bpftrace

    # VPN into the Hetzner "Lab" (service is disable by default)
    zerotierone
  ];

  # terraform Libvirt VM's for k8s testing
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        ovmf = {
          enable = true;
        };
        runAsRoot = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    lxd = { enable = true; };
    docker = {
      enable = true;
      # extraOptions = ''
      #   --insecure-registry 192.168.1.65:5000
      # '';
    };
  };
  # terraform can also be setup with LXD
  systemd.services.lxd.path = with pkgs; [
    lvm2
    thin-provisioning-tools
    e2fsprogs
  ];

  # system.nssDatabases.hosts = [ "libvirt libvirt_guest" ];

  # iSCSI
  services.iscsid.enable = true;

  imports = base_imports ++ iscsi_imports ++ [ ../modules/reading-vpn.nix ];
}
