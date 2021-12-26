{ lib, ... }: rec {
  name = lib.removeSuffix "\n" (builtins.readFile /etc/nixos/hostname);
  nixPath = (./. + "/${name}");
  import = file: nixPath + file;
}
