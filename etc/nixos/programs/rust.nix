{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    direnv
    nix-direnv

    # Manage rust outside of nix
    rustup

    # Debugger
    gdb

    clang
    llvmPackages.bintools
  ];
}
