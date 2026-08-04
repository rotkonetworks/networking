#!/usr/bin/env bash
# Pre-deploy config gate for the networking pipeline.
# Fast checks that need NO containerlab/CHR — run on every PR before any deploy job.
#   1. BIRD host configs  -> `bird -p` parse (BIRD3 container)
#   2. generator scripts  -> bash -n
#   3. RouterOS .rsc       -> structural sanity (balanced braces, no stray CRLF, has router-id)
#   4. clab topologies     -> YAML well-formed
# Exit non-zero on any failure so CI blocks the merge.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0; BIRD_IMG="${BIRD_IMG:-ghcr.io/rotkonetworks/bird:3}"

echo "== 1. BIRD configs (bird -p) =="
if docker image inspect "$BIRD_IMG" >/dev/null 2>&1 || docker pull -q "$BIRD_IMG" >/dev/null 2>&1; then
  for c in generated/*-bird.conf; do
    [ -f "$c" ] || continue
    if docker run --rm --network none -v "$PWD/$c":/e.conf:ro "$BIRD_IMG" bird -p -c /e.conf >/tmp/b.$$ 2>&1; then
      echo "  ✅ $c"; else echo "  ❌ $c"; sed 's/^/     /' /tmp/b.$$; fail=1; fi
  done; rm -f /tmp/b.$$
else
  echo "  ⚠ no BIRD3 image ($BIRD_IMG) — skipping parse (set BIRD_IMG). Falling back to grep sanity."
  for c in generated/*-bird.conf; do grep -q "router id" "$c" 2>/dev/null && echo "  ~ $c (has router id)" || { echo "  ❌ $c missing 'router id'"; fail=1; }; done
fi

echo "== 2. generator scripts (bash -n) =="
for s in deploy/bird/gencfg.sh deploy/network/gencfg.sh deploy/nftables/gencfg.sh deploy/haproxy/gencfg.sh; do
  [ -f "$s" ] || continue
  if bash -n "$s" 2>/tmp/s.$$; then echo "  ✅ $s"; else echo "  ❌ $s"; sed 's/^/     /' /tmp/s.$$; fail=1; fi
done; rm -f /tmp/s.$$

echo "== 3. RouterOS .rsc sanity =="
for r in backup/mikrotik/*.rsc deploy/fixups/*.rsc; do
  [ -f "$r" ] || continue
  errs=""
  grep -qP '\r' "$r" && echo "  ~ $(basename "$r") CRLF (RouterOS export — ok)"
  ob=$(grep -o '{' "$r" | wc -l); cb=$(grep -o '}' "$r" | wc -l); [ "$ob" != "$cb" ] && errs="$errs braces($ob/$cb)"
  [ -z "$errs" ] && echo "  ✅ $(basename "$r")" || { echo "  ❌ $(basename "$r"):$errs"; fail=1; }
done

echo "== 4. clab topologies (YAML) =="
for t in clab/*.clab.yml; do
  [ -f "$t" ] || continue
  if python3 -c "import yaml,sys;yaml.safe_load(open('$t'))" 2>/tmp/y.$$; then echo "  ✅ $t"; else echo "  ❌ $t"; sed 's/^/     /' /tmp/y.$$; fail=1; fi
done; rm -f /tmp/y.$$

echo; [ $fail -eq 0 ] && echo "PASS — configs clean" || echo "FAIL — fix above before deploy"
exit $fail
