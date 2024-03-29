{ config, lib, pkgs, ... }:
let host = import ../host.nix { inherit lib; };
in
{
  networking.hostName = host.name;

  networking.wireless.enable =
    false; # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Because we're not in the stone age

  # Bluetooth - this actually works ok for a change in linux!
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
}
