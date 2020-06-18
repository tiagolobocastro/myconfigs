# WARNING
# This is a very hacky script which messes with your cargo install
# allowing us to run cargo commands from nix within our own shell
# and also allows IDEA/VsCode to run it's analyzis properly
# ( todo: paths have been hardcoded which is not nice )
# Run at your own risk - YOU HAVE BEEN WARNED

create_bin() {
cat << EOF > $1/$2
#!/bin/bash
run_nix_bin() {
bin=\$(/usr/bin/which cargo)
if [ \$bin = \$(readlink -f ~/.cargo/bin/cargo) ]; then
  ( ~/.nix-profile/bin/nix-shell --run "$2 \$*" ~/git/Mayastor/shell.nix | tail -n +8 )
else
    echo "Odd... Should not be running outside our shell.. exit"
    exit 1
fi
}

run_nix_bin \$@
EOF
chmod +x $1/$2
}

loc=$(mktemp -d)

for f in ~/.cargo/bin/c*; do
    create_bin $loc $(basename $f)
done

cp -rT ~/.cargo/bin_originals ~/.cargo/bin
cp -rnT ~/.cargo/bin ~/.cargo/bin_originals
cp -rT $loc ~/.cargo/bin

rm -rf $loc
