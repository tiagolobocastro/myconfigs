#!/usr/bin/env sh
cd ~/git/Mayastor
nix-shell --command "nohup smartgit >/dev/null &"
