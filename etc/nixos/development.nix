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
    idea.idea-community
    (pkgs.smartgithg.overrideAttrs (oldAttrs: {
      version = "20.2.0";
      src = fetchurl {
        url = "https://www.syntevo.com/downloads/smartgit/smartgit-linux-20_2_0.tar.gz";
        sha256 = "02cqd3xpb6wl4sx44hg2qsdlg7bf666jhqgj0i11mqcyw0hcf0zy";
      };
    })) meld

    # Container development
    lxd thin-provisioning-tools lvm2 e2fsprogs
    skopeo
    
    # MayaData requirements
    slack
    zoom-us
    jitsi-meet-electron
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

    linuxPackages.bpftrace
  ];
}
