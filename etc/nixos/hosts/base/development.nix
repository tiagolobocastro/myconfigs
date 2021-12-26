{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  host = import ../host.nix { inherit lib; };
in
{
  imports = [ ../../programs/vscode.nix ];

  environment.systemPackages = with pkgs; [
    # Debugger
    gdb

    # GUIs
    unstable.jetbrains.clion
    # Visual Diff
    meld

    # Container development
    lxd
    thin-provisioning-tools
    lvm2
    e2fsprogs
    skopeo
    envsubst

    # MayaData requirements
    unstable.slack
    rustup
    kubernetes-helm
    niv

    # Formats
    jq

    # Networking
    unstable.curl

    # gpg keys
    kgpg
    gnupg
    pinentry-curses

    # DataCore
    unstable.teams
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    #pinentryFlavor = "curses";
  };

  virtualisation = {
    docker = {
      enable = true;
      extraOptions = ''
        --insecure-registry 192.168.1.137:5000
      '';
    };
  };
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };
}
