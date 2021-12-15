{ config, lib, pkgs, ... }:
let host = import ./host.nix { inherit lib; };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ./networking.nix
    ./system-packages.nix
    ./services.nix
    ./desktop-environment.nix
    ./development.nix

    (host.import "/hardware.nix")
    (host.import "/extra-configuration.nix")
    (host.import "/lang-fonts.nix")
  ];

  # for now
  security.sudo.wheelNeedsPassword = false;

  # Enable and configure zsh
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellInit = ''
      export EDITOR=vim
      export LIBVIRT_DEFAULT_URI=qemu:///system
      export REAL_PAGER=$PAGER
      export NIX_PAGER=cat
    '';
    promptInit =
      "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    ohMyZsh.enable = true;
    ohMyZsh.plugins = [
      "sudo"
      "docker"
      "history-substring-search"
      "git"
      "vi-mode"
      "kubectl"
      "colored-man-pages"
      "systemd"
      "man"
      "command-not-found"
      "extract"
    ];
  };

  programs.ssh.extraConfig = ''
    ServerAliveInterval 15
    ServerAliveCountMax 3'';

  users.users.tiago = {
    description = "Tiago Castro";
    isNormalUser = true;
    extraGroups =
      [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager" ];
    shell = pkgs.zsh;
  };

  services.fstrim.enable = true;
}
