{ lib, ... }:
let
  name = lib.removeSuffix "\n" (builtins.readFile /etc/nixos/hostname);
  nixPath = (./. + "/${name}");
  hostSpecificFile = file: nixPath + file;

  makeHost =
    {
      # Name for the Host
      name
    , # Base Configuration
      base ? [ ./base/default.nix ]
    , # Generic Program Modules to import
      programs ? [ ../programs/default.nix ]
    , # Configuration.nix specific to the Host (eg: State version)
      configuration ? (hostSpecificFile "/configuration.nix")
    , # Desktop Environment
      desktop ? (hostSpecificFile "/desktop-environment.nix")
    , # Networking
      networking ? (hostSpecificFile "/networking.nix")
    , # Hardware
      hardware ? (hostSpecificFile "/hardware.nix")
    , # Language and Fonts
      lang_fonts ? (hostSpecificFile "/lang-fonts.nix")
    , extra ? [ ]
    }: {
      inherit name base programs configuration desktop networking hardware lang_fonts extra;
      imports = [ configuration ] ++ base ++ programs ++ [ desktop ] ++ [ networking ] ++ [ hardware ] ++ [ lang_fonts ] ++ extra;
    };
  hosts = {
    asox = makeHost {
      name = "asox";
      extra = [
        ../features/mayadata.nix
      ];
    };
    lobox = makeHost {
      name = "lobox";
      extra = [
        ../features/mayadata-full.nix
      ];
    };
    cncf-dev = makeHost {
      name = "cncf-dev";
      extra = [
        ../features/mayadata.nix
      ];
    };
  };
  host = hosts.${name};
in
{
  name = host.name;
  imports = host.imports;
}
