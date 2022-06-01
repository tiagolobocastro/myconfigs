{ config, lib, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (callPackage ../modules/plugin-autenticacao-gov-pt.nix { })
  ];

  services.pcscd.enable = true;
}
