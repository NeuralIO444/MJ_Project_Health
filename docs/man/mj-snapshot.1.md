# mj-snapshot(1) — non-overwrite project snapshot

**Version:** 0.2.2-dev  
**Baseline:** stock macOS `/bin/zsh`

```
mj-snapshot <file.aep|file.c4d> [--out <versions-dir>]
mj-observe snapshot <file.aep|file.c4d> [--out <versions-dir>]
```

---

## DESCRIPTION

Creates a **new** copy of an After Effects or Cinema 4D project file. Never overwrites the source. Never overwrites an existing snapshot with the same content hash (hash-skip).

Output name pattern:

```
<basename>-<YYYYMMDD-HHMMSS>-<sha256_12>.<ext>
```

Example:

```
SH010_main-20260930-143022-a1b2c3d4e5f6.c4d
```

Default output directory: `<parent-of-source>/mj-versions`

---

## OPTIONS

| Option | Meaning |
|--------|---------|
| `--out DIR` | Versions directory (created if missing) |
| `-h`, `--help` | Short usage |

---

## BEHAVIOR

1. Require regular file ending in `.aep` or `.c4d` (case-insensitive).  
2. Compute SHA-256 (`shasum -a 256` or `openssl dgst -sha256`).  
3. If any file in `--out` already ends with `-<hash12>.ext`, print **SKIP** and exit 0.  
4. Else copy:
   - Prefer `cp -c` (APFS clone) when it succeeds  
   - Else plain `cp`  
5. Print destination path, full hash, and `source unchanged: <path>`.

---

## EXAMPLES

```zsh
# Next to the project
mj-snapshot ~/Shots/SH010/SH010.aep

# Explicit versions folder
mj-snapshot ~/Shots/SH010/SH010.c4d --out ~/AE_Versions/SH010

# Via unified CLI
mj-observe snapshot ~/Shots/SH010/SH010.aep --out ~/Shots/SH010/mj-versions
```

---

## SAFETY

- Source file is never opened for write  
- Snapshots are additive only  
- Suitable for Tier 0 Observer / hand-off packs (`mj-observe pack` copies `mj-versions/` into the archive)

---

## SEE ALSO

`mj-observe(1)`, `docs/STOCK_ZSH_BASELINE.md`
