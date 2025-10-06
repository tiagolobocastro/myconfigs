{ config, pkgs, lib, ... }:
let
  #unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  a = 1;
in
{
  options = {
    vscode.extensions = lib.mkOption { default = [ ]; };
    vscode.user = lib.mkOption { }; # <- Must be supplied
    vscode.homeDir = lib.mkOption { }; # <- Must be supplied
    nixpkgs.latestPackages = lib.mkOption { default = [ ]; };
  };

  config = {
    ###
    # DIRTY HACK
    # This will fetch latest packages on each rebuild, whatever channel you are at
    #nixpkgs.overlays = [
    #  (self: super: lib.genAttrs config.nixpkgs.latestPackages (pkg: unstable."${pkg}"))
    #];
    # END DIRTY HACK
    ###

    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = [ pkgs.vscode ];

    system.activationScripts.fix-vscode-extensions = {
      text = ''
        EXT_DIR=${config.vscode.homeDir}/.vscode/extensions
        mkdir -p $EXT_DIR
        chown ${config.vscode.user}:users $EXT_DIR
        for x in ${
          lib.concatMapStringsSep " " toString config.vscode.extensions
        }; do
            ln -sf $x/share/vscode/extensions/* $EXT_DIR/
        done
        chown -R ${config.vscode.user}:users $EXT_DIR
      '';
      deps = [ ];
    };
  };
}
