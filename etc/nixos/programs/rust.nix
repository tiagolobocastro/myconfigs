{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  imports = [ ../programs/vscode.nix ];

  environment.systemPackages = with pkgs; [
    # IDE
    unstable.jetbrains.clion
    # vscode - see import above

    # Manage rust outside of nix
    rustup

    # Debugger
    gdb
  ];
}
