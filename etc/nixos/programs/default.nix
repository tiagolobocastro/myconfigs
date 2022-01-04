{ config, pkgs, lib, ... }: {
  imports = [
    ./smartgit.nix
    ./vim.nix
    ./vscode.nix
    ./zsh.nix
    ./tmux.nix
  ];
}
