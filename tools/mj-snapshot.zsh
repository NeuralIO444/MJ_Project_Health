#!/bin/zsh
# mj-snapshot — non-overwrite hash snapshot for .aep / .c4d (stock zsh)
# Copies source to versions dir as name-YYYYMMDD-HHMMSS-<hash12>.ext
# Never modifies the source file.

emulate -L zsh
setopt err_return extended_glob null_glob

usage() {
  cat <<USAGE
mj-snapshot — non-overwrite project snapshot (Observer)

Usage:
  mj-snapshot <file.aep|file.c4d> [--out <versions-dir>]

Creates a copy named:
  <basename>-<timestamp>-<sha12><ext>

Skips if an identical hash snapshot already exists in the out dir (hash-skip).
Requires: shasum or openssl, cp. Optional: cp -c for APFS clone when available.
USAGE
}

have() { command -v "$1" >/dev/null 2>&1; }

hash_file() {
  local f="$1"
  if have shasum; then
    shasum -a 256 "$f" 2>/dev/null | awk '{print $1}'
  elif have openssl; then
    openssl dgst -sha256 "$f" 2>/dev/null | awk '{print $NF}'
  else
    print ""
    return 1
  fi
}

main() {
  local src="" outdir=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; return 0 ;;
      --out) outdir="$2"; shift 2 ;;
      *)
        if [[ -z "$src" ]]; then src="$1"; shift
        else print "Unknown arg: $1"; usage; return 1
        fi
        ;;
    esac
  done
  if [[ -z "$src" || ! -f "$src" ]]; then
    usage
    return 1
  fi
  case "${src:l}" in
    *.aep|*.c4d) ;;
    *) print "Only .aep or .c4d supported: $src"; return 1 ;;
  esac

  outdir="${outdir:-${src:h}/mj-versions}"
  mkdir -p "$outdir"

  local h
  h=$(hash_file "$src") || { print "hash failed"; return 1; }
  local short="${h[1,12]}"
  # hash-skip: any existing file ending with -short.ext
  local existing
  existing=("$outdir"/*-${short}.*(N))
  if (( ${#existing} )); then
    print "SKIP identical hash already snapshotted:"
    print "  ${existing[1]}"
    print "hash=$h"
    return 0
  fi

  local stamp
  stamp=$(date +%Y%m%d-%H%M%S 2>/dev/null || print unknown)
  local base="${src:t:r}"
  local ext="${src:e}"
  local dest="${outdir}/${base}-${stamp}-${short}.${ext}"

  # Prefer APFS clone when cp -c works; else regular copy
  if cp -c "$src" "$dest" 2>/dev/null; then
    print "CLONE $dest"
  else
    cp "$src" "$dest" || return 1
    print "COPY  $dest"
  fi
  print "hash=$h"
  print "source unchanged: $src"
}

main "$@"
