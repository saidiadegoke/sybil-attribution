#!/usr/bin/env bash
# Wave 2: the roster x veto factorial swept across attacker fractions.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
OUT="$ROOT/results/shards"; LOG="$ROOT/logs"; JOBS="$ROOT/logs/jobs2"
mkdir -p "$OUT" "$LOG" "$JOBS"; rm -f "$JOBS"/*.sh
for r in 1:4 5:8 9:12 13:16 17:20; do
  t="fac_${r/:/_}"
  cat > "$JOBS/$t.sh" <<JOB
#!/usr/bin/env bash
cd "$HERE"
echo "[start] $t \$(date +%H:%M:%S)"
octave-cli --eval "attr_setup(); attr_factorial_sweep($r, '$OUT/$t.csv');" > "$LOG/$t.log" 2>&1
echo "[done ] $t \$(date +%H:%M:%S) rc=\$?"
JOB
  chmod +x "$JOBS/$t.sh"
done
ls "$JOBS"/*.sh | xargs -P 3 -n 1 bash
echo "WAVE2_COMPLETE"
