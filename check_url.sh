#!/usr/bin/env bash

URL="$1"
INTERVAL=43200

if [ -z "$URL" ]; then
    echo "Usage: $0 URL"
    exit 1
fi

size() {
    curl -fsSL "$URL" 2>/dev/null | wc -c
}

s1=$(size)
s2=$(size)
s3=$(size)

baseline=$(((s1 + s2 + s3) / 3))
min=$s1
max=$s1
[ "$s2" -lt "$min" ] && min=$s2
[ "$s3" -lt "$min" ] && min=$s3
[ "$s2" -gt "$max" ] && max=$s2
[ "$s3" -gt "$max" ] && max=$s3

margin=$((max - min))
[ "$margin" -lt 100 ] && margin=100

low=$((baseline - margin))
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
