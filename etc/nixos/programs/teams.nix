{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (callPackage ../modules/teams.nix { })
  ];
}
