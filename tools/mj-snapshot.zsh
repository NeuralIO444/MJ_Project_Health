#!/bin/zsh
# mj-snapshot — non-overwrite hash snapshot for .aep / .c4d (stock zsh)
#
# Prefer a clean shell:
#   /bin/zsh -f tools/mj-snapshot.zsh <file> [--out <dir>]
#
# Fixed adapters under /bin and /usr/bin only. Never modifies the source.

emulate -L zsh
setopt err_return extended_glob null_glob warn_create_global
unsetopt nounset  # optional flags may be empty

# --- fixed stock adapters (do not rely on PATH) -----------------------------
typeset _BIN_CP="/bin/cp"
typeset _BIN_MKDIR="/bin/mkdir"
typeset _BIN_DATE="/bin/date"
typeset _USR_SHASUM="/usr/bin/shasum"
typeset _USR_OPENSSL="/usr/bin/openssl"
typeset _USR_AWK="/usr/bin/awk"
[[ -x /bin/cp ]] || _BIN_CP="cp"
[[ -x /bin/mkdir ]] || _BIN_MKDIR="mkdir"
[[ -x /bin/date ]] || _BIN_DATE="date"
# ---------------------------------------------------------------------------

usage() {
  cat <<USAGE
mj-snapshot — non-overwrite project snapshot (Observer)

USAGE
  /bin/zsh -f mj-snapshot.zsh <file.aep|file.c4d> [--out <versions-dir>]
  mj-observe snapshot <file.aep|file.c4d> [--out <versions-dir>]

DESCRIPTION
  Copy a project file to a versions directory. Never modifies the source.
  Output name: <basename>-<YYYYMMDD-HHMMSS>-<sha256_12>.<ext>
  Default --out: <parent>/mj-versions

  Hash-skip: if a file with the same content hash already exists in --out,
  print SKIP and exit 0 (no second copy).

OPTIONS
  --out DIR   Versions directory (created if missing)
  -h, --help  This help

REQUIRES
  /usr/bin/shasum or /usr/bin/openssl; /bin/cp.
  Prefers APFS clone (cp -c) when available.

EXAMPLES
  /bin/zsh -f mj-snapshot.zsh ~/Shots/SH010/SH010.aep
  mj-snapshot ~/Shots/SH010/SH010.c4d --out ~/Versions/SH010

MANUAL
  docs/man/mj-snapshot.1.md
USAGE
}

hash_file() {
  local f="$1"
  local out=""
  if [[ -x ${_USR_SHASUM} ]]; then
    out="$(${_USR_SHASUM} -a 256 "$f" 2>/dev/null | ${_USR_AWK} '{print $1}')"
  elif [[ -x ${_USR_OPENSSL} ]]; then
    out="$(${_USR_OPENSSL} dgst -sha256 "$f" 2>/dev/null | ${_USR_AWK} '{print $NF}')"
  else
    print -u2 "mj-snapshot: need /usr/bin/shasum or /usr/bin/openssl"
    return 1
  fi
  if [[ -z "$out" || ${#out} -lt 12 ]]; then
    print -u2 "mj-snapshot: hash failed for $f"
    return 1
  fi
  print -r -- "$out"
}

main() {
  local src="" outdir=""
  while (( $# > 0 )); do
    case "$1" in
      -h|--help)
        usage
        return 0
        ;;
      --out)
        if (( $# < 2 )); then
          print -u2 "mj-snapshot: --out requires a directory"
          return 1
        fi
        outdir="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        print -u2 "mj-snapshot: unknown option: $1"
        usage
        return 1
        ;;
      *)
        if [[ -z "$src" ]]; then
          src="$1"
          shift
        else
          print -u2 "mj-snapshot: unexpected argument: $1"
          usage
          return 1
        fi
        ;;
    esac
  done

  if [[ -z "$src" ]]; then
    usage
    return 1
  fi
  if [[ ! -f "$src" ]]; then
    print -u2 "mj-snapshot: not a regular file: $src"
    return 1
  fi
  if [[ ! -r "$src" ]]; then
    print -u2 "mj-snapshot: not readable: $src"
    return 1
  fi

  case "${src:l}" in
    *.aep|*.c4d) ;;
    *)
      print -u2 "mj-snapshot: only .aep or .c4d supported: $src"
      return 1
      ;;
  esac

  # Resolve to absolute path when possible (stock readlink may differ; use :A)
  src="${src:A}"
  outdir="${outdir:-${src:h}/mj-versions}"
  outdir="${outdir:A}"

  ${_BIN_MKDIR} -p "$outdir" || return 1

  local h short
  h="$(hash_file "$src")" || return 1
  short="${h[1,12]}"

  local -a existing
  existing=("$outdir"/*-${short}.*(N))
  if (( ${#existing} > 0 )); then
    print "SKIP identical hash already snapshotted:"
    print "  ${existing[1]}"
    print "hash=$h"
    return 0
  fi

  local stamp base ext dest
  stamp="$(${_BIN_DATE} +%Y%m%d-%H%M%S 2>/dev/null)" || stamp="unknown"
  base="${src:t:r}"
  ext="${src:e}"
  dest="${outdir}/${base}-${stamp}-${short}.${ext}"

  if [[ -e "$dest" ]]; then
    print -u2 "mj-snapshot: destination exists (refuse overwrite): $dest"
    return 1
  fi

  # Prefer APFS clone; fall back to full copy
  if ${_BIN_CP} -c "$src" "$dest" 2>/dev/null; then
    print "CLONE $dest"
  else
    ${_BIN_CP} "$src" "$dest" || return 1
    print "COPY  $dest"
  fi
  print "hash=$h"
  print "source unchanged: $src"
  return 0
}

main "$@"
