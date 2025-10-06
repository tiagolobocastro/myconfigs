{ config, pkgs, lib, ... }: {
  # Why?
  nixpkgs.config.allowUnfree = true;

  # Enable the Gnome Desktop Environment
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Desktop Apps
  environment.systemPackages = with pkgs; [
    # Kde specific
    kdePackages.partitionmanager
    kdePackages.ark

    guake
    tilix
    dconf-editor
    gnome-tweaks
    gnomeExtensions.just-perfection
    gnomeExtensions.vitals
    gnomeExtensions.unmess
    gnomeExtensions.vertical-workspaces
    gnomeExtensions.appindicator
    gnomeExtensions.dock-from-dash
    gnomeExtensions.bluetooth-battery-meter
    # Office
    #p3x-onenote
  ];

  services.udev.packages = [ pkgs.gnome-settings-daemon ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}

# Useful Tips:
# Undo Control+Alt+Arrows
# gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "[]"
# gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "[]"
# Set guake-toggle command on keyboard custom shortcuts
