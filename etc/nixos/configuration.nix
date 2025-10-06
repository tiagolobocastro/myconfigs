{ config, lib, pkgs, ... }:
let host = import ./hosts/host.nix { inherit lib; };
in
{
  # for now
  security.sudo.wheelNeedsPassword = false;

  programs.ssh.extraConfig = ''
    ServerAliveInterval 15
    ServerAliveCountMax 3
    # ClientAliveInterval 15
    # ClientAliveCountMax 3
  '';

  users.users.tiago = {
    description = "Tiago Castro";
    isNormalUser = true;
    extraGroups =
      [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager" "containerd" "kvm" ];
    shell = pkgs.zsh;
  };
  users.users.bob = {
    description = "Bob Castro";
    isNormalUser = true;
    extraGroups =
      [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager" "containerd" "kvm" ];
    # shell = pkgs.zsh;
  };
  # users.users.hypr = {
  #   description = "Tiago Castro for hyprland";
  #   isNormalUser = true;
  #   extraGroups =
  #     [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager" "containerd" "kvm" ];
  #   shell = pkgs.zsh;
  #   initialPassword = "a";
  # };


  hardware.graphics.enable=true;

  nix.settings.trusted-users = [ "root" "tiago" "hypr" "bob" ];

  services.fstrim.enable = true;

  imports = host.imports;

  #boot.binfmt.emulatedSystems = [ "x86_64-windows" ];

  # hardware.keyboard.qmk.enable = true;

  services.lvm = {
    boot.thin.enable = true;
    dmeventd.enable = true;
  };

  networking.hostId = "1653aabe";
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };
  environment.systemPackages = with pkgs; [ zfs libnvme ];

  services.zerotierone = { enable = true; };
}
