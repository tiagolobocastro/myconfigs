{ config, lib, pkgs, ... }: {
  imports = [
    ./networking.nix
    ./services.nix
    ./system-packages.nix
  ];
}
