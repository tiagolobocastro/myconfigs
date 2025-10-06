{ config, lib, pkgs, ... }: {

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    #font = "Lat2-Terminus16";
    font = "ter-124b";
    keyMap = "us";
    packages = [ pkgs.terminus_font ];
  };

  # Where's Wally?
  time.timeZone = "Europe/London";

  fonts = {
    fontDir.enable = true;
    packages = with pkgs;[ nerd-fonts.hasklug nerd-fonts.fira-code ];
  };
}
