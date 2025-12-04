{ config, lib, pkgs, ... }: {
  imports = [ ./mayadata-full.nix ./mayadata-ui.nix ];

  environment.systemPackages = with pkgs; [
    #virt-manager
    (virt-manager.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [wrapGAppsHook3];
      buildInputs = lib.lists.subtractLists [wrapGAppsHook3] old.buildInputs ++ [
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
      ];
    }))
  ];
}
