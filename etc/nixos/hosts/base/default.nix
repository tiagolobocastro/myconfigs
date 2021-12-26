{ config, lib, pkgs, ... }: {
  imports = [
    ./desktop-environment.nix
    ./development.nix
    ./networking.nix
    ./services.nix
    ./system-packages.nix
  ];
}
