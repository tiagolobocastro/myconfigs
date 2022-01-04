{ config, lib, pkgs, ... }: {
  # NVIDIA drivers
  nixpkgs.config.allowUnfree = true;

  imports = [ ../../desktop/kde.nix ../../desktop/common.nix ];
}
