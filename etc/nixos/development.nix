{ config, lib, pkgs,  ... }: 

let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in
{
  imports = [ ./vscode.nix ./iscsid.nix ];

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
    docker = { enable = true; };
  };

  # vscode configuration
  vscode.user = "tiago";
  vscode.homeDir = "/home/tiago";
  vscode.extensions = with pkgs.vscode-extensions; [
    ms-vscode.cpptools
  ];
  nixpkgs.latestPackages = [
    "vscode"
    "vscode-extensions"
  ];

  environment.systemPackages = with pkgs; [
    # Debugger
    gdb

    # GUIs
    unstable.idea.idea-community
    (pkgs.smartgithg.overrideAttrs (oldAttrs: {
      version = "20.1.3";
      src = fetchurl {
        url = "https://www.syntevo.com/downloads/smartgit/smartgit-linux-20_1_3.tar.gz";
        sha256 = "0lgk0fhjq4nia99ywrv2pgf4w2q797zibxlp5k768dkr52gsgqk9";
      };
    })) meld

    # Container development
    unstable.lxd thin-provisioning-tools lvm2 e2fsprogs
    skopeo
    
    # MayaData requirements
    unstable.slack
    unstable.zoom-us
    unstable.jitsi-meet-electron
    openiscsi
    rustup 
    (unstable.terraform.withPlugins(p: [
      p.null
      p.template
      p.kubernetes
      p.lxd
      p.libvirt
    ])) ansible virt-manager
    kubectl k9s 

    # Golang
    go
  ];
}
