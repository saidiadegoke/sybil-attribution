#!/usr/bin/env bash
# Wave 4: the four [TO RUN] items of §8.
#   attr_ledger      item 1  ledger-integrity metrics (third coverage channel)
#   attr_delay       item 2  re-mint delay sweep (delta)
#   attr_scaling     item 3  displacement scaling over s x host
#   attr_scale_topo  item 4  scale and topology
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
OUT="$ROOT/results/shards"; LOG="$ROOT/logs"; JOBS="$ROOT/logs/jobs4"
mkdir -p "$OUT" "$LOG" "$JOBS"; rm -f "$JOBS"/*.sh

mk () {  # $1 tag, $2 driver
  for r in 1:4 5:8 9:12 13:16 17:20; do
    t="$1_${r/:/_}"
    cat > "$JOBS/$t.sh" <<JOB
#!/usr/bin/env bash
cd "$HERE"
echo "[start] $t \$(date +%H:%M:%S)"
octave-cli --eval "attr_setup(); $2($r, '$OUT/$t.csv');" > "$LOG/$t.log" 2>&1
echo "[done ] $t \$(date +%H:%M:%S) rc=\$?"
JOB
    chmod +x "$JOBS/$t.sh"
  done
}
mk ledger    attr_ledger
mk delay     attr_delay
mk scaling   attr_scaling
mk topo      attr_scale_topo

ls "$JOBS"/*.sh | xargs -P 6 -n 1 bash
echo "WAVE4_COMPLETE"
