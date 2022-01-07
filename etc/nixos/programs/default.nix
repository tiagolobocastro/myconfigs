{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  imports = [
    ./smartgit.nix
    ./vim.nix
    ./vscode.nix
    ./zsh.nix
    ./tmux.nix
  ];

  environment.systemPackages = with pkgs; [
    unstable.bitwarden
  ];
}
