{ config, lib, pkgs, ... }: {

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Where's Wally?
  time.timeZone = "Europe/London";

  fonts = {
    fontDir.enable = true;
    packages = with pkgs;
      [ (nerdfonts.override { fonts = [ "Hasklig" "FiraCode" ]; }) ];
  };
}
