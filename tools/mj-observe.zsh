#!/bin/zsh
# mj-observe — unified Observer CLI (stock zsh baseline)
# Production: /bin/zsh + /usr/bin only. No Homebrew required.
#
# Prefer a clean shell (no user rc):
#   /bin/zsh -f tools/mj-observe.zsh <command> [args]
#
# Commands: help | describe | report | diff | pack | shot | snapshot

emulate -L zsh
setopt err_return extended_glob null_glob warn_create_global
unsetopt nounset

# --- fixed stock adapters ---------------------------------------------------
typeset _BIN_CP="/bin/cp"
typeset _BIN_MKDIR="/bin/mkdir"
typeset _BIN_DATE="/bin/date"
typeset _BIN_DF="/bin/df"
typeset _USR_GREP="/usr/bin/grep"
typeset _USR_TAR="/usr/bin/tar"
typeset _USR_SW_VERS="/usr/bin/sw_vers"
typeset _USR_PYTHON="/usr/bin/python3"
typeset _USR_OPEN="/usr/bin/open"
[[ -x /bin/cp ]] || _BIN_CP="cp"
[[ -x /bin/mkdir ]] || _BIN_MKDIR="mkdir"
[[ -x /bin/date ]] || _BIN_DATE="date"
[[ -x /bin/df ]] || _BIN_DF="df"
[[ -x /usr/bin/python3 ]] || _USR_PYTHON="python3"
[[ -x /usr/bin/tar ]] || _USR_TAR="tar"
# ---------------------------------------------------------------------------

MJ_OBSERVE_VERSION="0.2.1-dev"
SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"
TEMPLATE="${ROOT_DIR}/web/dashboard_template.html"

usage() {
  cat <<EOF
mj-observe ${MJ_OBSERVE_VERSION} — MographJailed Observer (stock zsh)

USAGE
  mj-observe <command> [options]

COMMANDS
  help              Show this help
  describe          Probe stock tools, c4dpy, MographJailed CLI
                    [--json]   reserved machine-readable form
  report            Build offline HTML dashboard + HEALTH.txt
                    --ingest <AE MJ_PROJECT_SUMMARY_1.json>
                    --lint   <AE MJ_EXPRESSION_LINT_1.json>
                    --c4d    <MJ_C4D_SCRAPE_1.json>
                    --out    <dir>   (default: .)
                    Need at least --ingest or --c4d
  diff              Compare two summary/scrape JSON files
                    mj-observe diff <old.json> <new.json>
  pack              Hand-off tarball (receipts, report, snapshots, MACHINE.txt)
                    mj-observe pack <shot-dir> [--out <dir>]
  shot              Discover .aep/.c4d, describe, report from mj-receipts/
                    mj-observe shot <shot-dir>
  snapshot          Non-overwrite hash snapshot (.aep|.c4d)
                    mj-observe snapshot <file> [--out <versions-dir>]

STATUS
  PASS       no missing assets/footage, no lint errors
  WARNINGS   lint warnings and/or unlinked AE footage
  BLOCKERS   missing AE footage / C4D assets and/or lint errors

EXAMPLES
  mj-observe describe
  mj-observe report --ingest sum.json --lint lint.json --c4d c4d.json --out /tmp/out
  open /tmp/out/mj-health-report.html
  mj-observe shot ~/Shots/SH010
  mj-observe snapshot ~/Shots/SH010/SH010.aep

RULES
  Read-only Observer. No source mutation. Stock Sequoia baseline (no Homebrew).
  Prefer: /bin/zsh -f tools/mj-observe.zsh <command> ...
  Full manual: docs/man/mj-observe.1.md
EOF
}

have() {
  # Prefer absolute stock paths when probing known tools
  case "$1" in
    python3) [[ -x ${_USR_PYTHON} ]] && return 0 ;;
    tar)     [[ -x ${_USR_TAR} ]] && return 0 ;;
    open)    [[ -x ${_USR_OPEN} ]] && return 0 ;;
  esac
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
  print "AE scrape: File > Scripts > MJ Project Health / scraper in After Effects."
  print "C4D scrape: c4dpy integrations/cinema4d/scene_health.py /path/shot.c4d"
  if (( as_json )); then
    print "(--json detailed envelope: TODO)"
  fi
}

cmd_report() {
  local ingest="" lint="" c4d="" outdir="."
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ingest) ingest="$2"; shift 2 ;;
      --lint) lint="$2"; shift 2 ;;
      --c4d) c4d="$2"; shift 2 ;;
      --out) outdir="$2"; shift 2 ;;
      *) print -u2 "Unknown arg: $1"; return 1 ;;
    esac
  done
  if [[ -z "$ingest" && -z "$c4d" ]]; then
    print -u2 "report requires --ingest <AE summary> and/or --c4d <MJ_C4D_SCRAPE_1>"
    return 1
  fi
  [[ -n "$ingest" && ! -f "$ingest" ]] && { print -u2 "missing ingest: $ingest"; return 1; }
  [[ -n "$c4d" && ! -f "$c4d" ]] && { print -u2 "missing c4d: $c4d"; return 1; }
  [[ -n "$lint" && ! -f "$lint" ]] && { print -u2 "missing lint: $lint"; return 1; }
  ${_BIN_MKDIR} -p "$outdir"
  local outfile="${outdir}/mj-health-report.html"
  if [[ ! -f "$TEMPLATE" ]]; then
    print -u2 "Missing template: $TEMPLATE"
    return 1
  fi

  if have python3; then
    INGEST="${ingest:-}" LINT="${lint:-}" C4D="${c4d:-}" TEMPLATE="$TEMPLATE" OUTFILE="$outfile" ${_USR_PYTHON} - <<'PY'
import json, os, re, datetime
ingest_path = os.environ.get("INGEST") or ""
lint_path = os.environ.get("LINT") or ""
c4d_path = os.environ.get("C4D") or ""
template = open(os.environ["TEMPLATE"], encoding="utf-8").read()

def load(path):
    if not path or not os.path.isfile(path):
        return {}
    with open(path, encoding="utf-8") as f:
        raw = json.load(f)
    return raw.get("data", raw) if isinstance(raw, dict) else {}

data = load(ingest_path)
lint = load(lint_path)
c4d = load(c4d_path)
findings = list(lint.get("findings") or [])
order = {"error": 0, "warning": 1, "info": 2}
findings.sort(key=lambda x: (order.get(str(x.get("severity", "")).lower(), 9), x.get("code", "")))

missing_ae = list(data.get("footageMissing") or [])
missing_c4d = list(c4d.get("assetsMissing") or [])
missing = list(missing_ae)
for m in missing_c4d:
    if m not in missing:
        missing.append(m)

status = "PASS"
if missing or int(lint.get("errors") or 0) > 0 or int(c4d.get("numMissing") or 0) > 0:
    status = "BLOCKERS"
elif int(lint.get("warnings") or 0) > 0 or list(data.get("footageUnlinked") or []):
    status = "WARNINGS"

project = (
    data.get("projectName")
    or c4d.get("projectName")
    or data.get("projectPath")
    or c4d.get("projectPath")
    or "—"
)

payload = {
    "status": status,
    "generatedAt": datetime.datetime.now().isoformat(timespec="seconds"),
    "projectName": project,
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
    "c4d": {
        "numAssets": c4d.get("numAssets"),
        "numMissing": c4d.get("numMissing"),
        "c4dVersion": c4d.get("c4dVersion"),
    }
    if c4d
    else None,
}
blob = json.dumps(payload, ensure_ascii=False)
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
if c4d:
    print("c4d_missing=%s" % c4d.get("numMissing"))
PY
  else
    cp "$TEMPLATE" "$outfile"
    print "$outfile (template only; python3 needed to inject data)"
  fi

  {
    print "MJ Shot Health"
    [[ -n "$ingest" ]] && print "ingest=$ingest"
    [[ -n "$lint" ]] && print "lint=$lint"
    [[ -n "$c4d" ]] && print "c4d=$c4d"
    print "report=$outfile"
  } > "${outdir}/HEALTH.txt"
  print "Wrote ${outdir}/HEALTH.txt"
}

cmd_diff() {
  local old="${1:-}" new="${2:-}"
  if [[ -z "$old" || -z "$new" || ! -f "$old" || ! -f "$new" ]]; then
    print -u2 "usage: mj-observe diff <old-summary.json> <new-summary.json>"
    return 1
  fi
  if have python3; then
    ${_USR_PYTHON} - "$old" "$new" <<'PY'
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
for key in ("numComps", "numLayers", "numExpressions", "numFonts", "numFootage", "numAssets", "numMissing", "numFindings", "errors", "warnings"):
    if key in a or key in b:
        print("%s: %s -> %s" % (key, a.get(key), b.get(key)))
PY
  else
    print -u2 "python3 required for diff on this build"
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
    print -u2 "usage: mj-observe pack <shot-dir> [--out <dir>]"
    return 1
  fi
  outdir="${outdir:-$shot}"
  ${_BIN_MKDIR} -p "$outdir"
  local stamp
  stamp="$(${_BIN_DATE} +%Y%m%d-%H%M%S 2>/dev/null)" || stamp="unknown"
  local name="${shot:t}"
  local stage="${outdir}/mj-handoff-${name}-${stamp}"
  mkdir -p "$stage/receipts" "$stage/snapshots"
  {
    print "MJ Hand-off Pack"
    print "shot=$shot"
    print "created=$stamp"
    print "----"
    ${_USR_SW_VERS} 2>/dev/null || true
    print "----"
    ${_BIN_DF} -h "$shot" 2>/dev/null || true
  } > "$stage/MACHINE.txt"
  local r
  for r in "$shot"/mj-receipts/*(N) "$shot"/receipts/*(N); do
    [[ -f "$r" ]] && cp "$r" "$stage/receipts/"
  done
  for r in "$shot"/mj-versions/*(N) "$shot"/versions/*(N); do
    [[ -f "$r" ]] && cp "$r" "$stage/snapshots/"
  done
  [[ -f "$shot/HEALTH.txt" ]] && cp "$shot/HEALTH.txt" "$stage/"
  [[ -f "$shot/mj-health-report.html" ]] && cp "$shot/mj-health-report.html" "$stage/"
  if have tar; then
    local tarball="${outdir}/mj-handoff-${name}-${stamp}.tar.gz"
    ${_USR_TAR} -czf "$tarball" -C "$outdir" "mj-handoff-${name}-${stamp}"
    print "Wrote $tarball"
  else
    print "Wrote folder $stage (tar not found)"
  fi
}

cmd_shot() {
  local shot="${1:-}"
  if [[ -z "$shot" || ! -d "$shot" ]]; then
    print -u2 "usage: mj-observe shot <shot-dir>"
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
    local ae_sum="" lint_f="" c4d_f=""
    for r in $rec; do
      if ${_USR_GREP} -q 'MJ_PROJECT_SUMMARY_1\|numComps' "$r" 2>/dev/null; then
        ae_sum="$r"
      elif ${_USR_GREP} -q 'MJ_EXPRESSION_LINT_1\|"findings"' "$r" 2>/dev/null; then
        lint_f="$r"
      elif ${_USR_GREP} -q 'MJ_C4D_SCRAPE_1\|assetsMissing' "$r" 2>/dev/null; then
        c4d_f="$r"
      fi
    done
    local report_args=()
    [[ -n "$ae_sum" ]] && report_args+=(--ingest "$ae_sum")
    [[ -n "$lint_f" ]] && report_args+=(--lint "$lint_f")
    [[ -n "$c4d_f" ]] && report_args+=(--c4d "$c4d_f")
    if (( ${#report_args} )); then
      cmd_report "${report_args[@]}" --out "$shot"
    else
      print "  (receipts present but no known summary schema)"
    fi
  else
    print "  (none)  Run AE Project Health / c4dpy scene_health.py; save under mj-receipts/"
  fi
  print "-- storage --"
  ${_BIN_DF} -h "$shot" 2>/dev/null || true
}

cmd_snapshot() {
  local snap="${ROOT_DIR}/tools/mj-snapshot.zsh"
  if [[ -f "$snap" ]]; then
    /bin/zsh -f "$snap" "$@"
  else
    print -u2 "mj-snapshot.zsh not found at $snap"
    return 1
  fi
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
    snapshot) cmd_snapshot "$@" ;;
    *) print -u2 "Unknown command: $cmd"; usage; return 1 ;;
  esac
}

main "$@"
