#!/bin/zsh
# mj-observe — unified Observer CLI (stock zsh baseline)
# Production: /bin/zsh + /usr/bin only. No Homebrew required.
#
# Commands: help | describe | report | diff | pack | shot

emulate -L zsh
setopt err_return no_unset 2>/dev/null || true
setopt extended_glob null_glob

MJ_OBSERVE_VERSION="0.1.0-dev"
SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"
TEMPLATE="${ROOT_DIR}/web/dashboard_template.html"

usage() {
  cat <<EOF
mj-observe ${MJ_OBSERVE_VERSION} — MographJailed Observer (stock zsh)

Usage:
  mj-observe help
  mj-observe describe [--json]
  mj-observe report --ingest <file> [--lint <file>] [--out <dir>]
  mj-observe diff <old-summary.json> <new-summary.json>
  mj-observe pack <shot-dir> [--out <dir>]
  mj-observe shot <shot-dir>   # Phase 1: discover + describe + report if receipts exist

Rules: read-only Observer; no source mutation; Sequoia stock baseline.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

probe_stock() {
  local t
  for t in zsh jq sips avmediainfo plutil shasum df stat tar ditto open python3; do
    if have "$t"; then
      print "OK  $t"
    else
      print "MISS $t"
    fi
  done
}

probe_c4dpy() {
  local p
  for p in /Applications/Maxon\ Cinema\ 4D*/c4dpy.app/Contents/MacOS/c4dpy(N); do
    print "OK  c4dpy  $p"
    return 0
  done
  print "MISS c4dpy  (install Cinema 4D for C4D Scene Health)"
}

probe_mj_cli() {
  local candidates=(
    "${HOME}/Documents/MographJailed/dist/mograph-jailed.zsh"
    "${HOME}/MographJailed/dist/mograph-jailed.zsh"
  )
  local c
  for c in $candidates; do
    if [[ -f "$c" ]]; then
      print "OK  mograph-jailed  $c"
      return 0
    fi
  done
  print "MISS mograph-jailed  (designer install optional for Protocol ops)"
}

cmd_describe() {
  local as_json=0
  [[ "${1:-}" == "--json" ]] && as_json=1
  print "mj-observe describe  (machine capabilities)"
  print "---- stock tools ----"
  probe_stock
  print "---- hosts ----"
  probe_c4dpy
  print "---- protocol ----"
  probe_mj_cli
  print "---- note ----"
  print "AE scrape: run File > Scripts > MJ scraper / Project Health in After Effects."
  print "C4D scrape: c4dpy scene_health.py /path/to/shot.c4d (when shipped)."
  if (( as_json )); then
    print "(--json detailed envelope: TODO P1)"
  fi
}

# Build dashboard HTML from fixture-shaped summary objects using python3 if present, else minimal sed note
cmd_report() {
  local ingest="" lint="" outdir="."
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ingest) ingest="$2"; shift 2 ;;
      --lint) lint="$2"; shift 2 ;;
      --out) outdir="$2"; shift 2 ;;
      *) print "Unknown arg: $1"; return 1 ;;
    esac
  done
  if [[ -z "$ingest" || ! -f "$ingest" ]]; then
    print "report requires --ingest <MJ_PROJECT_SUMMARY_1 json>"
    return 1
  fi
  mkdir -p "$outdir"
  local outfile="${outdir}/mj-health-report.html"
  if [[ ! -f "$TEMPLATE" ]]; then
    print "Missing template: $TEMPLATE"
    return 1
  fi

  if have python3; then
    INGEST="$ingest" LINT="${lint:-}" TEMPLATE="$TEMPLATE" OUTFILE="$outfile" python3 - <<'PY'
import json, os, re, datetime
ingest_path = os.environ["INGEST"]
lint_path = os.environ.get("LINT") or ""
template = open(os.environ["TEMPLATE"], encoding="utf-8").read()
with open(ingest_path, encoding="utf-8") as f:
    raw = json.load(f)
# accept either bare data or full envelope
data = raw.get("data", raw) if isinstance(raw, dict) else {}
lint = {}
findings = []
if lint_path and os.path.isfile(lint_path):
    with open(lint_path, encoding="utf-8") as f:
        lraw = json.load(f)
    lint = lraw.get("data", lraw) if isinstance(lraw, dict) else {}
    findings = list(lint.get("findings") or [])
    # risk map: errors, warnings, info
    order = {"error": 0, "warning": 1, "info": 2}
    findings.sort(key=lambda x: (order.get(str(x.get("severity","")).lower(), 9), x.get("code","")))

missing = list(data.get("footageMissing") or [])
status = "PASS"
if missing or int(lint.get("errors") or 0) > 0:
    status = "BLOCKERS"
elif int(lint.get("warnings") or 0) > 0 or list(data.get("footageUnlinked") or []):
    status = "WARNINGS"

payload = {
    "status": status,
    "generatedAt": datetime.datetime.now().isoformat(timespec="seconds"),
    "projectName": data.get("projectName") or data.get("projectPath") or "—",
    "numComps": data.get("numComps"),
    "numLayers": data.get("numLayers"),
    "numExpressions": data.get("numExpressions"),
    "numMissing": len(missing),
    "lint": {
        "errors": int(lint.get("errors") or 0),
        "warnings": int(lint.get("warnings") or 0),
        "info": int(lint.get("info") or 0),
    },
    "footprint": {
        "fonts": data.get("numFonts"),
        "effects": data.get("numEffects"),
    },
    "storage": "",
    "findings": findings[:50],
    "missing": missing,
    "capabilities": [],
}
blob = json.dumps(payload, ensure_ascii=False)
# replace window.MJ_DASHBOARD = { ... };
new_js = "window.MJ_DASHBOARD = " + blob + ";"
out = re.sub(
    r"window\.MJ_DASHBOARD\s*=\s*\{.*?\};",
    new_js,
    template,
    count=1,
    flags=re.S,
)
open(os.environ["OUTFILE"], "w", encoding="utf-8").write(out)
print(os.environ["OUTFILE"])
print("status=" + status)
PY
  else
    cp "$TEMPLATE" "$outfile"
    print "$outfile (template only; python3 needed to inject data)"
  fi

  # HEALTH.txt sidecar
  {
    print "MJ Shot Health"
    print "ingest=$ingest"
    [[ -n "$lint" ]] && print "lint=$lint"
    print "report=$outfile"
  } > "${outdir}/HEALTH.txt"
  print "Wrote ${outdir}/HEALTH.txt"
}

cmd_diff() {
  local old="${1:-}" new="${2:-}"
  if [[ -z "$old" || -z "$new" || ! -f "$old" || ! -f "$new" ]]; then
    print "usage: mj-observe diff <old-summary.json> <new-summary.json>"
    return 1
  fi
  if have python3; then
    python3 - "$old" "$new" <<'PY'
import json, sys
def load(p):
    o = json.load(open(p, encoding="utf-8"))
    return o.get("data", o) if isinstance(o, dict) else {}
a, b = load(sys.argv[1]), load(sys.argv[2])
def miss(d):
    return set(d.get("footageMissing") or d.get("assetsMissing") or [])
ma, mb = miss(a), miss(b)
print("=== MJ health diff ===")
print("new missing:     ", sorted(mb - ma) or "(none)")
print("resolved missing:", sorted(ma - mb) or "(none)")
for key in ("numComps", "numLayers", "numExpressions", "numFonts", "numFootage", "numFindings", "errors", "warnings"):
    if key in a or key in b:
        print(f"{key}: {a.get(key)} -> {b.get(key)}")
PY
  else
    print "python3 required for diff on this build"
    return 1
  fi
}

cmd_pack() {
  local shot="${1:-}"
  local outdir=""
  shift 2>/dev/null || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --out) outdir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  if [[ -z "$shot" || ! -d "$shot" ]]; then
    print "usage: mj-observe pack <shot-dir> [--out <dir>]"
    return 1
  fi
  outdir="${outdir:-$shot}"
  mkdir -p "$outdir"
  local stamp
  stamp=$(date +%Y%m%d-%H%M%S 2>/dev/null || print unknown)
  local name="${shot:t}"
  local stage="${outdir}/mj-handoff-${name}-${stamp}"
  mkdir -p "$stage/receipts"
  {
    print "MJ Hand-off Pack"
    print "shot=$shot"
    print "created=$stamp"
    print "----"
    sw_vers 2>/dev/null || true
    print "----"
    df -h "$shot" 2>/dev/null || true
  } > "$stage/MACHINE.txt"
  # copy receipts if present
  local r
  for r in "$shot"/mj-receipts/*(N) "$shot"/receipts/*(N); do
    [[ -f "$r" ]] && cp "$r" "$stage/receipts/"
  done
  [[ -f "$shot/HEALTH.txt" ]] && cp "$shot/HEALTH.txt" "$stage/"
  [[ -f "$shot/mj-health-report.html" ]] && cp "$shot/mj-health-report.html" "$stage/"
  if have tar; then
    local tarball="${outdir}/mj-handoff-${name}-${stamp}.tar.gz"
    tar -czf "$tarball" -C "$outdir" "mj-handoff-${name}-${stamp}"
    print "Wrote $tarball"
  else
    print "Wrote folder $stage (tar not found)"
  fi
}

cmd_shot() {
  local shot="${1:-}"
  if [[ -z "$shot" || ! -d "$shot" ]]; then
    print "usage: mj-observe shot <shot-dir>"
    return 1
  fi
  print "=== mj-observe shot: $shot ==="
  print "-- discover --"
  local aep c4d
  aep=("$shot"/**/*.aep(N[1,20]))
  c4d=("$shot"/**/*.c4d(N[1,20]))
  print "aep: ${#aep}  c4d: ${#c4d}"
  (( ${#aep} )) && printf '  %s\n' "${aep[@]}"
  (( ${#c4d} )) && printf '  %s\n' "${c4d[@]}"
  print "-- capabilities --"
  cmd_describe
  print "-- receipts --"
  local rec
  rec=("$shot"/mj-receipts/*(N) "$shot"/receipts/*(N))
  if (( ${#rec} )); then
    printf '  %s\n' "${rec[@]}"
    # try report if we find summary-like json
    local candidate=""
    for r in $rec; do
      if grep -q 'MJ_PROJECT_SUMMARY_1\|numComps' "$r" 2>/dev/null; then
        candidate="$r"
        break
      fi
    done
    if [[ -n "$candidate" ]]; then
      cmd_report --ingest "$candidate" --out "$shot"
    fi
  else
    print "  (none)  Run AE Project Health / C4D scrape, save receipts under mj-receipts/"
  fi
  print "-- storage --"
  df -h "$shot" 2>/dev/null || true
}

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true
  case "$cmd" in
    help|-h|--help) usage ;;
    describe) cmd_describe "$@" ;;
    report) cmd_report "$@" ;;
    diff) cmd_diff "$@" ;;
    pack) cmd_pack "$@" ;;
    shot) cmd_shot "$@" ;;
    *) print "Unknown command: $cmd"; usage; return 1 ;;
  esac
}

main "$@"
