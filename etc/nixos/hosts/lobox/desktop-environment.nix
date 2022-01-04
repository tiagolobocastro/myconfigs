{ config, lib, pkgs, ... }: {
  # NVIDIA drivers
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  imports = [ ../../desktop/kde.nix ../../desktop/common.nix ];
}
