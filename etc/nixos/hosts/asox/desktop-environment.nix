{ config, lib, pkgs, ... }: {
  # NVIDIA drivers
  nixpkgs.config.allowUnfree = true;
}
