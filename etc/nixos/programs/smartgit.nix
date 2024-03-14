{ config, pkgs, lib, ... }:
let
  version = "23.1.2";
  version_ = builtins.replaceStrings [ "." ] [ "_" ] version;
in
{
  environment.systemPackages = with pkgs; [
    (smartgithg.overrideAttrs (oldAttrs: rec {
      inherit version;
      src = fetchurl {
        url =
          "https://www.syntevo.com/downloads/smartgit/smartgit-linux-${version_}.tar.gz";
        sha256 = "sha256-gXfHmRPUhs8s7IQIhN0vQyx8NpLrS28ufNNYOMA4AXw=";
      };
      desktopItem = oldAttrs.desktopItem.overrideAttrs (desktopAttrs: {
        text =
          let
            oldExec = builtins.match ''
              .*(Exec=[^
              ]+
              ).*''
              desktopAttrs.text;
            oldTerminal = builtins.match ''
              .*(Terminal=[^
              ]+
              ).*''
              desktopAttrs.text;
            matches = oldExec ++ (if builtins.isNull oldTerminal then [ ] else oldTerminal);
            replacements =
              if builtins.isNull oldTerminal then [
                # TODO: get this as an argument somehow?
                ''
                  Exec=/home/tiago/git/myconfigs/maya/smargit.sh
                  Terminal=true
                ''
              ] else [
                ''
                  Exec=/home/tiago/git/myconfigs/maya/smargit.sh
                ''
                ''
                  Terminal=true
                ''
              ];
          in
          builtins.replaceStrings matches replacements desktopAttrs.text;
      });
      postInstall = builtins.replaceStrings [ "${oldAttrs.desktopItem}" ]
        [ "${desktopItem}" ]
        (oldAttrs.postInstall or "");
    }))
  ];
}
