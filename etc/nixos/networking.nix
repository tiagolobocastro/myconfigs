{ config, lib, pkgs, ... }:
let host = import ./host.nix { inherit lib; };
in {
  networking.hostName = host.name;

  imports = [ (host.import "/extra-networking.nix") ];
}
