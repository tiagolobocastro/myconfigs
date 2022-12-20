{ config, pkgs, lib, ... }:
{
  imports = [
    ./vim.nix
    ./zsh.nix
    ./tmux.nix
  ];

  environment.systemPackages = with pkgs; [
    killall
  ];
}
