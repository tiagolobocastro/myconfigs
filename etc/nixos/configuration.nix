{ config, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # My hardware configuration
      ./hardware.nix
      ./networking.nix
      ./system-packages.nix
      ./lang-fonts.nix
      ./services.nix
      ./desktop-environment.nix
      ./development.nix
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
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
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

  users.users.tiago = {
    description = "Tiago Castro";
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager"];
    shell = pkgs.zsh;
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
  };

  nix.extraOptions = ''
    min-free = ${toString (65 * 1024 * 1024 * 1024)}
  '';

  services.fstrim.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
