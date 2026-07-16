#!/bin/sh

CACHE="$HOME/.cache/pacman-updates"

mkdir -p "$(dirname "$CACHE")"

checkupdates | wc -l > "$CACHE"
