{ config, lib, pkgs, ... }:
{
  imports = [ ../modules/vscode.nix ];

  environment.systemPackages = [ pkgs.vscode ];
  # vscode configuration
  vscode.user = "tiago";
  vscode.homeDir = "/home/tiago";
  vscode.extensions = with pkgs.vscode-extensions; [ ms-vscode.cpptools ];
  nixpkgs.latestPackages = [ "vscode" "vscode-extensions" ];
}
