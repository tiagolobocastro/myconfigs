{ config, pkgs, lib, ... }:
let
  version = "21.2.2";
  version_ = builtins.replaceStrings [ "." ] [ "_" ] version;
  pkgs_21_11 = import <nixos-21.11> { config = config.nixpkgs.config; };
in
{
  environment.systemPackages = with pkgs; [
    (pkgs_21_11.smartgithg.overrideAttrs (oldAttrs: rec {
      inherit version;
      src = fetchurl {
        url =
          "https://www.syntevo.com/downloads/smartgit/smartgit-linux-${version_}.tar.gz";
        sha256 = "10v6sg0lmjby3v8g3sk2rzzvdx5p69ia4zz2c0hbf30rk0p6gqn3";
      };
      desktopItem = oldAttrs.desktopItem.overrideAttrs (desktopAttrs: {
        buildCommand =
          let
            oldExec = builtins.match ''
              .*(Exec=[^
              ]+
              ).*''
              desktopAttrs.buildCommand;
            oldTerminal = builtins.match ''
              .*(Terminal=[^
              ]+
              ).*''
              desktopAttrs.buildCommand;
            matches = oldExec ++ oldTerminal;
            replacements = [
              # TODO: get this as an argument somehow?
              ''
                Exec=/home/tiago/git/myconfigs/maya/smargit.sh
              ''
              ''
                Terminal=true
              ''
            ];
          in
          assert builtins.length matches == builtins.length replacements;
          builtins.replaceStrings matches replacements desktopAttrs.buildCommand;
      });
      # desktopItem = oldAttrs.desktopItem.overrideAttrs (desktopAttrs: {
      #   text =
      #     let
      #       oldExec = builtins.match ''
      #         .*(Exec=[^
      #         ]+
      #         ).*''
      #         desktopAttrs.text;
      #       oldTerminal = builtins.match ''
      #         .*(Terminal=[^
      #         ]+
      #         ).*''
      #         desktopAttrs.text;
      #       matches = oldExec ++ (if builtins.isNull oldTerminal then [] else oldTerminal);
      #       replacements = if builtins.isNull oldTerminal then [
      #         # TODO: get this as an argument somehow?
      #         ''
      #           Exec=/home/tiago/git/myconfigs/maya/smargit.sh
      #           Terminal=true
      #         ''
      #       ] else [
      #         ''
      #           Exec=/home/tiago/git/myconfigs/maya/smargit.sh
      #         ''
      #         ''
      #           Terminal=true
      #         ''
      #       ];
      #     in
      #     builtins.replaceStrings matches replacements desktopAttrs.text;
      # });
      postInstall = builtins.replaceStrings [ "${oldAttrs.desktopItem}" ]
        [ "${desktopItem}" ]
        (oldAttrs.postInstall or "");
    }))
  ];
}
