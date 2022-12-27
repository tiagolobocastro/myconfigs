{ config, lib, pkgs, ... }: {
  imports = [ ./mayadata-full.nix ./mayadata-ui.nix ];

  environment.systemPackages = with pkgs; [ virt-manager ];
}
