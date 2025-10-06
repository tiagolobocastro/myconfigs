{ config, lib, pkgs, ... }:
let
  unstable = import
      (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/71a6392e367b08525ee710a93af2e80083b5b3e2.tar.gz)
      # reuse the current configuration
      { config = config.nixpkgs.config; };
in
{
  imports = [ ../programs/smartgit.nix ../programs/rust-ui.nix ];

  environment.systemPackages = with pkgs; [
    # Social Networking
    slack
    unstable.teams-for-linux
  ];
}
