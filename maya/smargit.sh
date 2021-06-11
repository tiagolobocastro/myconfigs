#!/usr/bin/env sh
cd ~/git/chief
nix-shell --arg nomayastor true --command "nohup smartgit >/dev/null &"
