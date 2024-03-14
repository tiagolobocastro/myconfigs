{ config, lib, pkgs, ... }: {
  imports = [ ../programs/smartgit.nix ../programs/rust-ui.nix ../programs/teams.nix ];

  environment.systemPackages = with pkgs; [
    # Social Networking
    slack
    #teams-for-linux
    #teams
  ];
}
