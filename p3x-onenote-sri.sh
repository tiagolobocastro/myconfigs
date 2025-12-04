#!/usr/bin/env bash

set -euo pipefail

fetch_sri() {
    local version=$1
    local plat=$2
    local system=$3
    local hashi
    hashi=$(nix-prefetch-url https://github.com/patrikx3/onenote/releases/download/v${version}/P3X-OneNote-${version}${plat}.AppImage)
    error=$?
    if [ $error -gt 0 ]; then
        echo "ERROR $error Fetching $version for $system" >&2
        return $error
    fi
    nix hash convert --hash-algo sha256 --to sri $hashi --extra-experimental-features nix-command
}

display_sri() {
    local system=$1
    local sri=$2
    echo "      $system = \"$sri\";"
}

system_plat() {
    local system=$1
    case $system in
        x86_64-linux) echo ""; shift;;
        aarch64-linux) echo "-arm64"; shift;;
        armv7l-linux) echo "-armv7l"; shift;;
        *) echo "BAD SYSTEM: $system"; exit 2
    esac
}

show_sris() {
    local version="$1"

    local systems=("aarch64-linux" "armv7l-linux" "x86_64-linux")
    local sris=("" "" "")

    for index in "${!systems[@]}"; do
        local system="${systems[$index]}"
        local plat sri
        plat=$(system_plat "$system")
        sri=$(fetch_sri "$version" "$plat" "$system")
        sris[$index]="$sri"
    done

    for index in "${!systems[@]}"; do
        system="${systems[$index]}"
        sri="${sris[$index]}"
        display_sri "$system" "$sri"
    done
}

if [ -z "${VERSION:-}" ]; then
    echo "Please specify VERSION=xxxx"
    exit 3
fi
show_sris "$VERSION"

