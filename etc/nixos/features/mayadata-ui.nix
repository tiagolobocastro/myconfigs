{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in {
  imports = [ ../programs/smartgit.nix ../programs/rust-ui.nix ];

  environment.systemPackages = with pkgs; [
    # Social Networking
    unstable.slack
    unstable.teams
  ];
}
