{ lib, ... }: rec {
  name = lib.removeSuffix "\n" (builtins.readFile ./hostname);
  nixPath = (./. + "/${name}");
  import = file: nixPath + file;
}
