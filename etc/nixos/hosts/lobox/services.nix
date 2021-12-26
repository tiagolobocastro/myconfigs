{ config, lib, pkgs, ... }: {
  imports = [ ../../modules/iscsid.nix ];
  services.iscsid.enable = true;

  systemd.services.lxd.path = with pkgs; [
    lvm2
    thin-provisioning-tools
    e2fsprogs
  ];
}
