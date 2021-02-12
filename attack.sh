#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: ./attack.sh REPORT_FILENAME"
    exit 1
fi

FILENAME="$1.report"

log() {
    printf "[%s] %s\n" "$(date)" "$@"
}

log "Launching server..."
rm -f ready
racket -l errortrace -t bench.rkt &
while [ ! -f ready ]
do
    sleep 0.25
done

log "Warming up..."
vegeta attack -duration=5s -rate 10/s < targets \
    | vegeta report

log "Benchmarking..."
vegeta attack -duration=30s -rate 4000/s < targets \
    | tee "$FILENAME" \
    | vegeta report

log "Stopping server..."
kill %1

log "Waiting for report..."
wait %1
