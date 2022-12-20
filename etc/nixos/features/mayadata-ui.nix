{ config, lib, pkgs, ... }:
{
  imports = [ ../programs/smartgit.nix ../programs/rust-ui.nix ];

  environment.systemPackages = with pkgs; [
    # Visual Diff
    meld
  ];
}
