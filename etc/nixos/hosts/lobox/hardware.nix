{ config, lib, pkgs, ... }:
##let unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
let a = 1;
in
{
  imports = [ /etc/nixos/hardware-configuration.nix ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  #boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  # Add systemd to enable kexec
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot = {
    #kernelPackages = pkgs.linuxPackages_6_14;
    kernelParams = [ "mitigations=off" ]; # "iscolcpus=14,15" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ]; #"nvidia_drm.fbdev=1" "nvidia_drm.modeset=1"
    kernelModules = [
      #"nbd"
      #"nvmet"
      #"nvmet-tcp"
      "nvme-tcp"
      "nf_conntrack"
      "ip_tables"
      "nf_nat"
      "overlay"
      "netlink_diag"
      "br_netfilter"
      "dm-snapshot"
      "dm-mirror"
      "dm_thin_pool"
    ];
    # blacklistedKernelModules = [ "l2tp_ppp" "l2tp_netlink" "l2tp_core" ];
    extraModprobeConfig = ''
      options kvm_amd nested=1
      #options nf_conntrack hashsize=393216
      # options iwlwifi 11n_disable=1 swcrypto=1
    '';
    kernel.sysctl = { "vm.nr_hugepages" = 4096; };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    # open = false;
    # modesetting.enable = true;
    # open = false;
    # nvidiaSettings = true;
    # powerManagement.enable = true;
    # powerManagement.finegrained = false;
  };

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  #services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
  #  "monitor.bluez.properties" = {
  #      "bluez5.enable-sbc-xq" = true;
  #      "bluez5.enable-msbc" = true;
  #      "bluez5.enable-hw-volume" = true;
  #      "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" "a2dp" ];
  #      "bluez5.autoswitch-profile" = true;
  #  };
  #};


  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];

  # Do we need this?
  hardware.enableAllFirmware = true;

 # security.pam.loginLimits = [
 #   { domain = "*"; item = "nofile"; type = "-"; value = "32768"; }
 #   { domain = "*"; item = "memlock"; type = "-"; value = "65536"; }
 # ];
}
