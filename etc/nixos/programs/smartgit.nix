{ config, pkgs, lib, ... }:
let
  version = "21.1.3";
  version_ = builtins.replaceStrings [ "." ] [ "_" ] version;
in
{
  environment.systemPackages = with pkgs; [
    (pkgs.smartgithg.overrideAttrs (oldAttrs: rec {
      inherit version;
      src = fetchurl {
        url =
          "https://www.syntevo.com/downloads/smartgit/smartgit-linux-${version_}.tar.gz";
        sha256 = "1ic5rz2ywpmk4ay338nhxsmfc0rspqrw7nmavg3dbv8vbi2dabsk";
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
      postInstall = builtins.replaceStrings [ "${oldAttrs.desktopItem}" ]
        [ "${desktopItem}" ]
        (oldAttrs.postInstall or "");
    }))
  ];
}
