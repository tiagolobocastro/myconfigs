{ config, lib, pkgs,  ... }: 

let
  unstable = import<nixos-unstable> { config = config.nixpkgs.config; };
in
{
  # Containers and virtual machines
  virtualisation = {
    libvirtd = {
      enable = false;
      qemu.ovmf.enable = true;
      qemu.runAsRoot = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    lxd = { enable = false; };
    docker = {
      enable = true;
      extraOptions = ''
        --insecure-registry 192.168.1.137:5000
      '';
    };
  };
}
