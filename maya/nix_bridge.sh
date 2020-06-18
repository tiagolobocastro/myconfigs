run_nix_bin() {
# replace this with a better check!
  bin=$(/usr/bin/which cargo)
  if [ $bin = $(readlink -f ~/.cargo/bin/cargo) ]; then
    ( ~/.nix-profile/bin/nix-shell --run "$2 $*" ~/git/Mayastor/shell.nix )
  else
    echo "Odd... Should not be running outside our shell.. exit"
    exit 1
  fi
}

