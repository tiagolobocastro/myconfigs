#!/usr/bin/env sh
[ -d ~/git/chief ] && cd ~/git/chief
[ -d ~/git/mayastor-control-plane ] && cd ~/git/mayastor-control-plane
nix-shell --arg nomayastor true --command "nohup smartgit >/dev/null &"
sleep 1
