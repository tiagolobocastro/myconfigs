{ pkgs ? import <nixpkgs> { }, stdenv ? pkgs.stdenv }:

let
  version = "2.0.63";
  name = "plugin-autenticacao-gov-pt";

  src =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      pkgs.fetchurl
        {
          url = "https://aplicacoes.autenticacao.gov.pt/plugin/plugin-autenticacao-gov.deb";
          sha256 = "0ayzsdqy83f68548gj696a5gg3b2bc6hjnnbapp6kxsw4ybldg3w";
        }
    else
      throw "is not supported on ${stdenv.hostPlatform.system}";

in
stdenv.mkDerivation {
  pname = name;
  inherit version;

  system = "x86_64-linux";

  inherit src;

  nativeBuildInputs = with pkgs; [
    dpkg
    wrapGAppsHook
    glib
    autoPatchelfHook
  ];

  preFixup = with pkgs; with stdenv.lib; ''
    gappsWrapperArgs+=( \
      --prefix PATH : ${makeBinPath [ jre which ]} \
      --prefix PATH : "/nix/store/mb9yriz3jzrxc6d9c9528rswgqdjbkmb-pcsclite-1.9.0/lib" \
      --prefix LD_LIBRARY_PATH : "/nix/store/mb9yriz3jzrxc6d9c9528rswgqdjbkmb-pcsclite-1.9.0/lib"
      --prefix JRE_HOME : ${jre} \
      --prefix JAVA_HOME : ${jre} \
    ) \
  '';

  buildInputs = with pkgs; [ jre gnome3.adwaita-icon-theme gtk3 pcsclite pcsctools ccid ];

  dontUnpack = true;
  installPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    mv $out/usr/* $out
    rm -rf $out/usr

    for icon_size in 32 48 64 128 256; do
        path=$icon_size'x'$icon_size
        icon=$out/share/plugin-autenticacao-gov/plugin_autenticacao_gov_$icon_size.png
        mkdir -p $out/share/icons/hicolor/$path/apps
        cp $icon $out/share/icons/hicolor/$path/apps/plugin-autenticacao-gov.png
    done
  '';

  postFixup = ''
    # Fix the desktop link
    substituteInPlace $out/share/applications/plugin-autenticacao-gov.desktop \
                            --replace /usr/bin/java ${pkgs.jre}/bin/java \
                            --replace /usr/share $out/share
  '';

  meta = with stdenv.lib; {
    description = "Authenticate with ${name}";
    homepage = "https://aplicacoes.autenticacao.gov.pt/";
    license = licenses.unfree;
    maintainers = with stdenv.lib.maintainers; [ tiagolobocastro ];
    platforms = [ "x86_64-linux" ];
  };
}
