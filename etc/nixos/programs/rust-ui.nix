{ config, lib, pkgs, ... }:
{
  imports = [ ../programs/vscode.nix ];

  environment.systemPackages = with pkgs; [
    # IDE
    # after installing the rust-analyzer plugin, we must manually run:
    # nix-shell -p patchelf --run "patchelf --set-interpreter $(nix-instantiate --eval '<nixpkgs>' -A glibc.outPath | 
    # sed 's/"//g')/lib64/ld-linux-x86-64.so.2 ~/.local/share/JetBrains/CLion2021.2/intellij-rust/bin/linux/x86-64/intellij-rust-native-helper
    jetbrains.clion
  ];
}
