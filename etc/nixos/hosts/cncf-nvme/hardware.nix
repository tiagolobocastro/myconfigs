{ config, lib, pkgs, ... }:
{
  boot = {
    kernelParams = [ "mitigations=off" "coretemp" ];
    kernelModules = [
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
}
