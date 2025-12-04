{ config, lib, pkgs, ... }:
let
  # The Base
  base_imports = [ ./mayadata.nix ];
  # iSCSI
  iscsi_imports = [ ../modules/iscsid.nix ];
in
rec {
  environment.systemPackages = with pkgs; [
    # Kubernetes
    (terraform.withPlugins (p: [ p.dmacvicar_libvirt p.hashicorp_null p.terraform-lxd_lxd p.hashicorp_kubernetes p.hashicorp_helm p.hashicorp_local ])) # deploy local cluster via terraform
    ansible

    # DBG
    linuxPackages.bpftrace

    # VPN into the Hetzner "Lab" (service is disabled by default)
    zerotierone

    #openfortivpn

    #(google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
  ];

  #systemd.coredump.enable = true;

  # terraform Libvirt VM's for k8s testing
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        # ovmf = {
        #   enable = true;
        # };
        runAsRoot = true;
      };
      allowedBridges = [
        "virbr0"
        "br0"
        "virbr1"
        "talos3d3a9d82"
      ];
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    # lxd = { enable = true; };
    docker = {
      enable = true;
      # extraOptions = ''
      #   --insecure-registry 192.168.1.65:5000
      # '';
    };
  };
  # terraform can also be setup with LXD
  # systemd.services.lxd.path = with pkgs; [
  #   lvm2
  #   thin-provisioning-tools
  #   e2fsprogs
  #   lvm2_dmeventd
  # ];

  system.nssDatabases.hosts = [ "libvirt libvirt_guest" ];
  #services.resolved.enable = true;
  services.nscd.enable = true;

  # iSCSI
  # services.iscsid.enable = true;

  imports = base_imports;
  # ++ iscsi_imports ++ [ ../modules/reading-vpn.nix ];
}
