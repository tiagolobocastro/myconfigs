{ config, lib, pkgs, ... }:
let
  networkmanager-l2tp = pkgs.networkmanager-l2tp.overrideAttrs (oldAttrs:
    {
      postPatch = ''
        substituteInPlace src/nm-l2tp-service.c --replace "authby=secret" "authby=xauthpsk\n  xauth_identity=tiago.castro\n  dpddelay=30\n  dpdtimeout=120\n  dpdaction=clear"
        # substituteInPlace src/nm-l2tp-service.c --replace "type=transport" "type=transport"
      '';
    }
  );
  vpn_ip = "";
  psk = "";
  user = "";
  pass = "";
in
{

  environment.systemPackages = with pkgs; [
    strongswan
    lsof
  ];

  # NetworkManager does not support symlink secrets, so simply write by hand
  # environment.etc."ipsec.secrets".text = ''
  #   include ipsec.d/*.secrets
  #   include ipsec.d/ipsec.nm-l2tp.secrets
  # '';
  environment.etc."ipsec.conf".text = ''
    include ipsec.secrets
  '';
  environment.etc."ipsec.d/reading.secrets".text = ''
    : PSK "${psk}"
    ${user} : XAUTH "${pass}"
  '';
  environment.etc."strongswan.d/unencrypted.conf".text = ''
    charon {
      accept_unencrypted_mainmode_messages = yes
      keep_alive = 10s
    }
    # starter {
    #   config_file = /etc/ipsec.conf
    # }
  '';
  # environment.etc."NetworkManager/system-connections/Reading.nmconnection" = {
  #   text = ''
  #     [connection]
  #     id=Reading
  #     uuid=83af0333-7008-4637-8353-cf51e98d5874
  #     type=vpn
  #     metered=2
  #     permissions=user:tiago:;

  #     [vpn]
  #     gateway=${vpn_ip}
  #     ipsec-enabled=yes
  #     ipsec-pfs=no
  #     ipsec-esp=3des-sha1!
  #     ipsec-ike=3des-sha1-modp1024!
  #     ipsec-psk=59D7B588ACABDA02
  #     password-flags=1
  #     refuse-chap=yes
  #     refuse-eap=yes
  #     refuse-mschap=yes
  #     refuse-pap=yes
  #     user=tiago.castro
  #     service-type=org.freedesktop.NetworkManager.l2tp

  #     [ipv4]
  #     dns-search=
  #     ignore-auto-dns=true
  #     may-fail=false
  #     method=auto
  #     never-default=true
  #     route1=10.20.30.59/24

  #     [ipv6]
  #     addr-gen-mode=stable-privacy
  #     dns-search=
  #     method=auto

  #     [proxy]
  #   '';
  #   mode = "0600";
  # };
  # systemd.services.NetworkManager = {
  #   environment.STRONGSWAN_CONF = lib.mkForce "/etc/strongswan.d/unencrypted.conf";
  #   restartTriggers = [
  #     # Restart NM, otherwise we'd use the non-patched l2tp service
  #     "${networkmanager-l2tp}/lib/NetworkManager/VPN/nm-l2tp-service.name"
  #     config.environment.etc."NetworkManager/system-connections/Reading.nmconnection".source
  #   ];
  # };
  # # Not great, but not sure how else to do this other than perhaps using overlays
  # environment.etc."NetworkManager/VPN/nm-l2tp-service.name".source = lib.mkForce
  #  "${networkmanager-l2tp}/lib/NetworkManager/VPN/nm-l2tp-service.name";


  # # Manual ipsec + x2lp
  # # sudo ipsec up Rg
  # # echo "c l2tp tiago.castro pass" | sudo tee /var/run/xl2tpd/control
  # # or restart xl2tpd service
  # services.libreswan = {
  #   enable = true;
  # };
  services.strongswan = {
    enable = false;
    secrets = [
      "ipsec.d/*.secrets"
    ];
    connections.Rg = {
      authby = "xauthpsk";
      left = "%defaultroute";
      xauth_identity = "${user}";
      auto = "add";
      esp = "3des-sha1!";
      ike = "3des-sha1-modp1024!";
      ikelifetime = "86400s";
      keyexchange = "ikev1";
      keyingtries = "1";
      keylife = "86400s";
      rekeymargin = "30m";
      right = "${vpn_ip}";
      leftprotoport = "17/1701";
      rightprotoport = "17/1701";
      type = "transport";
    };
  };
  services.xl2tpd = {
    enable = false;
    #serverIp = "${vpn_ip}";
    #clientIpRange = "10.20.30.100-120";
    extraXl2tpOptions = ''
      ; Nada
    '';
  };
  #systemd.services.xl2tpd.serviceConfig.ExecStart = lib.mkForce "${pkgs.xl2tpd}/bin/xl2tpd -D -c /tmp/nm/xl2tpd.conf -s /etc/xl2tpd/l2tp-secrets -p /run/xl2tpd/pid -C /run/xl2tpd/control";
  systemd.services.xl2tpd.serviceConfig.ExecStart = lib.mkForce "${pkgs.xl2tpd}/bin/xl2tpd -D -c /home/tiago/xl2tpd.conf -s /etc/xl2tpd/l2tp-secrets -p /run/xl2tpd/pid -C /run/xl2tpd/control";
  systemd.services.strongswan.environment.STRONGSWAN_CONF = lib.mkForce "/home/tiago/.config/strongswan/ipsec.conf";
}
