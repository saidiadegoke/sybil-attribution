#!/usr/bin/env bash
# Wave added 2026-11-15 for the FEIC 2026 revision: sensitivity (20 seeds, 5 shards).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUT="$ROOT/results/shards/sens"; LOG="$ROOT/logs"
mkdir -p "$OUT" "$LOG"
for r in 1:4 5:8 9:12 13:16 17:20; do
  t="sens_${r/:/_}"
  ( cd "$HERE" && octave-cli --eval "attr_setup(); attr_sensitivity($r, '$OUT/$t.csv');" > "$LOG/$t.log" 2>&1; echo "[done] $t rc=$?" ) &
done
wait
