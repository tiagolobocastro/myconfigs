#!/usr/bin/env sh
[ -d ~/git/mayastor/controller ] && cd ~/git/mayastor/controller
nix-shell --arg nomayastor true --command "nohup smartgit >/dev/null &"
sleep 1
