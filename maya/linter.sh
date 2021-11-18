#prettier --version
#prettier --config .prettierrc --check csi/moac/*.js mayastor-test/*.js

cargo fmt --version
cargo fmt --all

cargo clippy --version
cargo clippy --all --all-targets $1 -- -D warnings

