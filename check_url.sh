#!/usr/bin/env bash

URL="$1"
INTERVAL=43200

if [ -z "$URL" ]; then
    echo "Usage: $0 URL"
    exit 1
fi

size() {
    curl -fsSL "$URL" 2>/dev/null \
        | LC_ALL=C tr -cd '\11\12\15\40-\176' \
        | wc -c
}

baseline=$(size)
margin=50

low=$((baseline - margin))
[ "$low" -lt 0 ] && low=0
high=$((baseline + margin))

echo "Baseline=${baseline}B Range=${low}-${high}B"

while true; do
    current=$(size)
    if [ "$current" -lt "$low" ] || [ "$current" -gt "$high" ]; then
        echo "[$(date '+%F %T')] Significant change: ${current}B (baseline ${baseline}B)"
    else
        echo "[$(date '+%F %T')] OK: ${current}B"
    fi
    sleep "$INTERVAL"
done
