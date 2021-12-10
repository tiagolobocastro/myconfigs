{ config, lib, pkgs, ... }: 
let
  unstable = import<nixos-unstable> { config = config.nixpkgs.config; };
in
{
  
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  # Add systemd to enable kexec
  boot.loader.systemd-boot.enable = true;

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    kernelParams = [ "mitigations=off" "coretemp" ];
    kernelModules = [
      #"brd"
      "nbd"
      "nvmet"
      "nvmet-tcp"
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
    extraModprobeConfig = ''
      options kvm_amd nested=1
      options nf_conntrack hashsize=393216
    '';
    kernel.sysctl = { "vm.nr_hugepages" = 4096; };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Do we need this?
  hardware.enableAllFirmware = true;
}
