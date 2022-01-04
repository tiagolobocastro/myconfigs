{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    kgpg
    gnupg
    pinentry-curses
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    #pinentryFlavor = "curses";
  };
}
