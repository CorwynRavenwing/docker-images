#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <image-name> <command...>" >&2
    exit 1
fi

IMAGE="$1"
shift

# Run with --init to reap zombies and handle signals, plus a timeout guard 
# so hanging legacy binaries (like PHP 5.1 futex blocks) fail cleanly instead of freezing.
exec timeout --signal=KILL 5s docker run --rm --init "$IMAGE" "$@"
