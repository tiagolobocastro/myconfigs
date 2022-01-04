{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  imports = [ ./rust.nix ./smartgit.nix ];

  environment.systemPackages = with pkgs; [
    git
    # Visual Diff
    meld

    # Container development
    lxd
    thin-provisioning-tools
    lvm2
    e2fsprogs
    skopeo
    envsubst

    # k8s
    kubernetes-helm
    kubectl
    k9s

    # Social Networking
    unstable.slack
    unstable.teams

    # Update sources.nix
    niv

    # Formats
    jq

    # OpenApi devel
    unstable.curl
  ];

  # Mayastor and ctrlp are tested using containers
  virtualisation = {
    docker = {
      enable = true;
      extraOptions = ''
        --insecure-registry 192.168.1.137:5000
      '';
    };
  };
  # Local registry to test local images
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };
}
