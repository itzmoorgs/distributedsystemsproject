#!/bin/sh
set -eu
OUT=$1; mkdir -p "$OUT"; : "${URLS:=http://presentation-entry/}" "${CONCURRENCY:=20}" "${DURATION:=30}" "${BENCHMARK:=true}" "${DELAY:=1}"
printf '%s\n' "$URLS" > "$OUT/urls.txt"
FLAGS="-c $CONCURRENCY -t ${DURATION}s -f $OUT/urls.txt"
[ "$BENCHMARK" = "true" ] && FLAGS="$FLAGS -b" || FLAGS="$FLAGS -d $DELAY"
siege $FLAGS | tee "$OUT/siege.log"
