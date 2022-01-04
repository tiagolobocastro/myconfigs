{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  # The Base
  imports = [ ./mayadata.nix ];

  environment.systemPackages = with pkgs; [
    # Kubernetes
    unstable.terraform-full # deploy local cluster via terraform
    ansible
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
  # terraform can also be setup with LXD
  systemd.services.lxd.path = with pkgs; [
    lvm2
    thin-provisioning-tools
    e2fsprogs
  ];

  # iSCSI
  imports = [ ../../modules/iscsid.nix ];
  services.iscsid.enable = true;
}
