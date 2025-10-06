{ config, lib, pkgs, ... }: {
  imports = [ ../programs/rust.nix ../programs/gpg.nix ];

  environment.systemPackages = with pkgs; [
    # Visual Diff
    meld

    git
    protobuf

    # Container development
    # lxd-lts
    thin-provisioning-tools
    lvm2
    e2fsprogs
    skopeo
    envsubst

    # k8s
    kubernetes-helm
    kubectl
    k9s
    krew

    nvme-cli

    # Update sources.nix
    niv

    # Formats
    jq

    # OpenApi devel
    curl
  ];

  # Mayastor and ctrlp are tested using containers
  virtualisation = {
    docker = {
      enable = true;
      # extraOptions = ''
      #   --insecure-registry 192.168.1.65:5000
      # '';
    };
  };
  # Local registry to test local images
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
    enableGarbageCollect = true;
    extraConfig = {
      log.level = "info";
    };
  };
  systemd.services.docker-registry.serviceConfig.Environment = [
    "OTEL_TRACES_EXPORTER=none"
  ];

  networking.firewall = {
    allowedTCPPorts = [ 5000 ];
    # Allow docker compose tests to reach the host
    interfaces."mayabridge0".allowedTCPPorts = [ 8082 ];
    # Allow k8s containers to pull from the host's registry
    interfaces."virbr1".allowedTCPPorts = [ 5000 ];
  };
}
