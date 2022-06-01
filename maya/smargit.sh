#!/usr/bin/env sh
[ -d ~/git/mayastor/controller ] && cd ~/git/mayastor/controller
[ -d ~/git/bolt/mobs ] && cd ~/git/bolt/mobs
[ -d ~/git/bolt/controller ] && cd ~/git/bolt/controller
nix-shell --arg nomayastor true --command "nohup smartgit >/dev/null &"
sleep 1
