{ config, lib, pkgs,  ... }: 

let
  unstable = import<nixos-unstable> { config = config.nixpkgs.config; };
in
{
  imports = [ ./vscode.nix ./iscsid.nix ];

  # Containers and virtual machines
  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    lxd = { enable = true; };
    docker = {
      enable = true;
      extraOptions = ''
        --insecure-registry 192.168.1.137:5000
      '';
    };
  };

  # vscode configuration
  vscode.user = "tiago";
  vscode.homeDir = "/home/tiago";
  vscode.extensions = with pkgs.vscode-extensions; [
    ms-vscode.cpptools
  ];
  nixpkgs.latestPackages = [
    "vscode"
    "vscode-extensions"
  ];

  environment.systemPackages = with pkgs; [
    # Debugger
    gdb

    brave

    # GUIs
    drawio
    jetbrains.goland
    unstable.idea.idea-community
    unstable.jetbrains.clion

    (pkgs.smartgithg.overrideAttrs (oldAttrs: rec {
      version = "21.1.3";
      src = fetchurl {
        url = "https://www.syntevo.com/downloads/smartgit/smartgit-linux-21_1_3.tar.gz";
        sha256 = "1ic5rz2ywpmk4ay338nhxsmfc0rspqrw7nmavg3dbv8vbi2dabsk";
      };
      desktopItem = oldAttrs.desktopItem.overrideAttrs (desktopAttrs: {
        buildCommand =
          let
            oldExec = builtins.match ".*(Exec=[^\n]+\n).*" desktopAttrs.buildCommand;
            oldTerminal = builtins.match ".*(Terminal=[^\n]+\n).*" desktopAttrs.buildCommand;
            matches = oldExec ++ oldTerminal;
            replacements = [ "Exec=/home/tiago/git/myconfigs/maya/smargit.sh\n" "Terminal=true\n" ];
          in
          assert builtins.length matches == builtins.length replacements;
          builtins.replaceStrings matches replacements desktopAttrs.buildCommand;
      });
      postInstall = builtins.replaceStrings [ "${oldAttrs.desktopItem}" ] [ "${desktopItem}" ] (oldAttrs.postInstall or "");
    }))
    meld

    # Container development
    lxd thin-provisioning-tools lvm2 e2fsprogs
    skopeo
    envsubst
    
    # MayaData requirements
    unstable.slack
    discord
    zoom-us
    jitsi-meet-electron
    openiscsi
    rustup
    #(terraform.withPlugins(p: [
    #  p.null
    #  p.template
    #  p.kubernetes
    #  p.lxd
    #  p.libvirt
    #  p.helm
    #]))
    unstable.terraform-full
    ansible virt-manager
    kubectl k9s 
    kubernetes-helm

    # Golang
    go pkg-config alsaLib gopls

    linuxPackages.bpftrace

    # Java
    jdk11

    # Formats
    jq

    # Networking
    tcpdump
    wireshark
    unstable.curl

    #gpg
    kgpg gnupg pinentry-curses

    zerotierone

    niv
    cntr
    direnv

    # DataCore
    unstable.teams

    # Used by tmux
    xclip
  ];
  services.zerotierone = {
    enable = false;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    #pinentryFlavor = "curses";
  };
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 10000;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      # So we can use transparency (needed by pretty zsh plugins)
      # set -g default-terminal screen-256color 

      # Le Mice
      setw -g mouse on

      # Use Alt-vim keys without prefix key to switch panes
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D 
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # For vi copy mode bindings
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i"
    '';  
  };
}
