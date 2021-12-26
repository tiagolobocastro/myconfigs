{ lib, ... }:
let
  name = lib.removeSuffix "\n" (builtins.readFile /etc/nixos/hostname);
  nixPath = (./. + "/${name}");
  import = file: nixPath + file;

  makeHost =
    {
      # Name for the Host
      name
    , # Base Configuration
      base ? [ ./base/default.nix ]
    , # Generic Program Modules to import
      programs ? [ ../programs/default.nix ]
    , # Configuration.nix specific to the Host (eg: State version)
      configuration ? (import "/configuration.nix")
    , # Desktop Environment
      desktop ? (import "/desktop-environment.nix")
    , # Networking
      networking ? (import "/networking.nix")
    , # Hardware
      hardware ? (import "/hardware.nix")
    , # Language and Fonts
      lang_fonts ? (import "/lang-fonts.nix")
    , # Development
      development ? (import "/development.nix")
    , extra ? [ ]
    }: {
      inherit name base programs configuration desktop networking hardware lang_fonts extra;
      imports = [ configuration ] ++ base ++ programs ++ [ desktop ] ++ [ networking ] ++ [ hardware ] ++ [ lang_fonts ] ++ extra;
    };
  hosts = {
    asox = makeHost {
      name = "asox";
      programs = [
        ../programs/zsh.nix
        ../programs/vim.nix
      ];
    };
    lobox = makeHost {
      name = "lobox";
      programs = [
        ../programs/zsh.nix
        ../programs/vim.nix
      ];
      extra = [ (import "/services.nix") ];
    };
  };
  host = hosts.${name};
in
{
  name = host.name;
  imports = host.imports;
}
