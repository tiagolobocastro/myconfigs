{ config, lib, pkgs, ... }:
let
  host = import ../host.nix { inherit lib; };
  # l2tp = (pkgs.networkmanager-l2tp.overrideAttrs (oldAttrs:
  #   {
  #     postPatch = ''
  #       substituteInPlace src/nm-l2tp-service.c --replace "authby=secret" "authby=xauthpsk\n  xauth_identity=tiago.castro\n  dpddelay=30\n  dpdtimeout=120\n  dpdaction=clear"
  #     '';
  #   }
  # )
  # );
in
{
  networking.hostName = host.name;

  networking.wireless.enable =
    false; # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Because we're not in the stone age
  networking.networkmanager.wifi.powersave = false;

  # Bluetooth - this actually works ok for a change in linux!
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.enableIPv6 = false;
  networking.interfaces.enp34s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  networking.extraHosts =
  ''
    10.0.0.6 api-rest.mayastor.openebs.io
  '';

}
