#!/usr/bin/env bash
# Link this repository's OS profiles into a UniXNU checkout's profiles/os/, which is the only
# place UniXNU reads them from. Run once per checkout; re-running is harmless.
# usage: scripts/install-os-profile.sh [UNIXNU_CHECKOUT]   (default: board.toml [package] unixnu)
set -euo pipefail
DEVICE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UNIXNU=${1:-$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1],"rb"))["package"]["unixnu"])' "$DEVICE/board.toml")}
case "$UNIXNU" in /*) ;; *) UNIXNU=$(cd "$DEVICE/$UNIXNU" && pwd) ;; esac
for profile in "$DEVICE"/os-profiles/*/; do
	name=$(basename "$profile")
	target="$UNIXNU/profiles/os/$name"
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		echo "install-os-profile.sh: $target exists and is not our link; leaving it" >&2
		continue
	fi
	ln -sfn "${profile%/}" "$target"
	echo "install-os-profile.sh: $name -> $target"
done
