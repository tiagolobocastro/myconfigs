{ config, lib, pkgs, ... }:
let
  host = import ../host.nix { inherit lib; };
in
{
  networking.hostName = host.name;

  networking.wireless.enable =
    false; # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Because we're not in the stone age
  networking.networkmanager.wifi.powersave = false;

  # Bluetooth - this actually works ok for a change in linux!
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
       ControllerMode = "dual";
       #Experimental = true;
       #Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  security.rtkit.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.enableIPv6 = true;
  networking.interfaces.enp39s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall = {
    enable = true;
    checkReversePath = false;
    allowedTCPPorts = [ 22 ];

    trustedInterfaces = [ "lxdbr0" "virbr1" ];

    #interfaces."virbr1".allowedTCPPorts = [ 8082 ];
    #extraCommands = ''
    #  #iptables -A INPUT -i mayabridge0 -j ACCEPT
    #'';
  };

  # networking.extraHosts =
  # ''
  #   10.0.0.6 api-rest.mayastor.openebs.io
  # '';

  #imports = [ ../../modules/reading-vpn.nix ];
}
