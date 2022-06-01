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
    #./plugin-autenticacao-gov-pt.nix
  ];

  environment.systemPackages = with pkgs; [
    unstable.zoom-us

    killall

    obs-studio

    vlc
  ];
}
