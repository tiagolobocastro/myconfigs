{ config, pkgs, ... }: {
  nix.gc = {
    automatic = false;
    dates = "weekly";
  };

  imports = [ ./development.nix ];

  nix.extraOptions = ''
    min-free = ${toString (65 * 1024 * 1024 * 1024)}
  '';
}
