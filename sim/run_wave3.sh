#!/usr/bin/env bash
# Wave 3: cross-host attribution -- the roster x veto factorial on HEED and Tao-IT2.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
OUT="$ROOT/results/shards"; LOG="$ROOT/logs"; JOBS="$ROOT/logs/jobs3"
mkdir -p "$OUT" "$LOG" "$JOBS"; rm -f "$JOBS"/*.sh
for r in 1:4 5:8 9:12 13:16 17:20; do
  t="hosts_${r/:/_}"
  cat > "$JOBS/$t.sh" <<JOB
#!/usr/bin/env bash
cd "$HERE"
echo "[start] $t \$(date +%H:%M:%S)"
octave-cli --eval "attr_setup(); attr_hosts($r, '$OUT/$t.csv');" > "$LOG/$t.log" 2>&1
echo "[done ] $t \$(date +%H:%M:%S) rc=\$?"
JOB
  chmod +x "$JOBS/$t.sh"
done
ls "$JOBS"/*.sh | xargs -P 5 -n 1 bash
echo "WAVE3_COMPLETE"
