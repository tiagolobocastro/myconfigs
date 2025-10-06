{ config, lib, pkgs, ... }:
{
  imports = [ ../modules/vscode.nix ];

  # vscode configuration
  vscode.user = "tiago";
  vscode.homeDir = "/home/tiago";
  vscode.extensions = with pkgs.vscode-extensions; [ ms-vscode.cpptools ];
  nixpkgs.latestPackages = [ "vscode" "vscode-extensions" ];
 # environment.systemPackages = with pkgs; [
  #(vscode-with-extensions.override {
  #  vscodeExtensions = with vscode-extensions; [
  #    ms-vscode.cpptools
  #  ];
  #})
  #scode.fhs
  #];
}
