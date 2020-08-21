# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz)
    # reuse the current configuration
    { config = config.nixpkgs.config; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./iscsid.nix
      ./vscode.nix
    ];

  vscode.user = "tiago";
  vscode.homeDir = "/home/tiago";
  vscode.extensions = with pkgs.vscode-extensions; [
    ms-vscode.cpptools
  ];
  nixpkgs.latestPackages = [
    "vscode"
    "vscode-extensions"
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "nodev"; # "nodev" for efi only

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelPatches = [ {
      name = "brd patch";
      patch = null;
      extraConfig = ''
          BLK_DEV_RAM m
      '';
    } ];
    kernelParams = [ "mitigations=off" "coretemp" ];
    kernelModules = [
      "brd"
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
      options brd rd_size=102400 rd_nr=10
      options nf_conntrack hashsize=393216
    '';
    kernel.sysctl = { "vm.nr_hugepages" = 2048; };
  };

  networking.hostName = "lobox"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    lxd = { enable = true; };
    docker = { enable = false; };
  };
  systemd.services.lxd.path = with pkgs; [ lvm2 thin-provisioning-tools e2fsprogs ];
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };


  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp34s0.useDHCP = true;
  networking.interfaces.wlo1.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override { python = python3; }).customize{
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-lastplace vim-plug ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ vim-nix fzf fzf-vim ack-vim vim-airline vim-airline-themes nerdtree ];
      };
      vimrcConfig.customRC = ''
        set backspace=indent,eol,start
        let $pkgsVimPlug = '${pkgs.vimPlugins.vim-plug}'
        let $myvim = '/home/tiago/git/myconfigs'
        let g:vimplugged = '/home/tiago/.vim/plugged'
        if filereadable($pkgsVimPlug."/share/vim-plugins/vim-plug/plug.vim")
          source $pkgsVimPlug/share/vim-plugins/vim-plug/plug.vim
        endif
        if filereadable($myvim."/vim/vim.vim")
          source $myvim/vim/vim.vim
        endif
      '';
    })
    # used by plugins
    nodejs yarn fzf silver-searcher
    neovim wget chromium pciutils firefox-bin htop inxi lm_sensors
    zsh oh-my-zsh terminator manpages git nixfmt keepass unstable.lxd
    (unstable.terraform.withPlugins(p: [
      p.null
      p.template
      p.kubernetes
      p.lxd
      p.libvirt
      ])) gdb
    thin-provisioning-tools lxd lvm2 e2fsprogs unzip kubectl
    # extra KDE apps
    kate kcalc spectacle yakuake ark partition-manager kdesu
    unstable.idea.idea-community rustup

    (pkgs.smartgithg.overrideAttrs (oldAttrs: {
      version = "20.1.3"; 
      src = fetchurl {
        url = "https://www.syntevo.com/downloads/smartgit/smartgit-linux-20_1_3.tar.gz";
        sha256 = "0lgk0fhjq4nia99ywrv2pgf4w2q797zibxlp5k768dkr52gsgqk9";
      };
    }))

    unstable.slack (unstable.zoom-us.overrideAttrs (oldAttrs: {
      installPhase = oldAttrs.installPhase + ''
        rm $out/share/zoom-us/libturbojpeg.so
        cp libturbojpeg.so.0.1.0 $out/share/zoom-us/libturbojpeg.so
      '';
    }))

    onedrive gparted skopeo openiscsi ansible k9s virt-manager astyle
  ];

  services.iscsid.enable = true;

  services.flatpak.enable = true;
  #xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-kde ];

  # for now
  security.sudo.wheelNeedsPassword = false;

  # Enable and configure zsh
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellInit = ''
      export EDITOR=vim
      export LIBVIRT_DEFAULT_URI=qemu:///system
    '';
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    ohMyZsh.enable = true;
    ohMyZsh.plugins = [ 
      "sudo"
      "docker"
      "history-substring-search"
      "git"
      "vi-mode"
      "kubectl"
      "colored-man-pages"
      "systemd"
      "man"
      "command-not-found"
      "extract"
    ];
  };

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [
      powerline-fonts
      unifont		  # International languages
      nerdfonts
      noto-fonts
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.enableAllFirmware = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "eurosign:e"; # what's this for??
  
  # NVIDIA drivers
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tiago = {
    description = "Tiago Castro";
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "docker" "lxd" "lxc" "fuse" "networkmanager"];
    shell = pkgs.zsh;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}

