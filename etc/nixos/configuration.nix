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
      [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager" ];
    shell = pkgs.zsh;
  };

  nix.trustedUsers = [ "root" "tiago" ];

  services.fstrim.enable = true;

  imports = host.imports;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
