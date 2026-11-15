#!/usr/bin/env bash
# Full campaign at a publishable seed budget (20 seeds), sharded across cores.
# Each shard is a generated script writing its own CSV; analysis merges them.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUT="$ROOT/results/shards"; LOG="$ROOT/logs"; JOBS="$ROOT/logs/jobs"
mkdir -p "$OUT" "$LOG" "$JOBS"; rm -f "$JOBS"/*.sh

mkjob () {  # $1 tag, $2 octave call
  cat > "$JOBS/$1.sh" <<JOB
#!/usr/bin/env bash
cd "$HERE"
echo "[start] $1 \$(date +%H:%M:%S)"
octave-cli --eval "attr_setup(); $2" > "$LOG/$1.log" 2>&1
echo "[done ] $1 \$(date +%H:%M:%S) rc=\$?"
JOB
  chmod +x "$JOBS/$1.sh"
}

for r in 1:4 5:8 9:12 13:16 17:20; do
  t="adv_${r/:/_}"; mkjob "$t" "attr_adversary($r, '$OUT/$t.csv');"
done
for r in 1:10 11:20; do
  t="abl_${r/:/_}"; mkjob "$t" "attr_ablations($r, '$OUT/$t.csv');"
done
for r in 1:5 6:10 11:15 16:20; do
  t="ksw_${r/:/_}"; mkjob "$t" "attr_ksweep($r, '$OUT/$t.csv');"
done

ls "$JOBS"/*.sh | xargs -P 6 -n 1 bash
echo "ALL_SHARDS_COMPLETE"
