# Security & blast radius — red-team auditable notes

**Scope:** `tools/mj-observe.zsh`, `tools/mj-snapshot.zsh` (Observer CLI)  
**Version under review:** 0.2.1-dev  
**Date:** 2026-09-30  
**Trust model:** User intentionally runs the tool on their own Mac with their own files.

This is not a formal penetration test. It is a structured attack-surface and blast-radius review so another engineer (or red team) can re-check the same claims.

---

## 1. Trust boundaries

```text
┌─────────────────────────────────────────────────────────────┐
│  User (same uid as the shell)                               │
│  Chooses: shot dirs, receipt paths, --out destinations      │
└───────────────────────────┬─────────────────────────────────┘
                            │ argv + readable files
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  mj-observe / mj-snapshot   (/bin/zsh -f recommended)       │
│  Fixed adapters: /bin/*, /usr/bin/*                         │
└─────────────┬───────────────────────────────┬───────────────┘
              │ write                         │ read-only
              ▼                               ▼
     --out / mj-versions              ingest/lint/c4d JSON
     report.html, HEALTH.txt          .aep/.c4d (snapshot source)
     tar.gz hand-off                  template HTML
                                      df / sw_vers (metadata)
```

| Boundary | Who crosses it | Policy |
|----------|----------------|--------|
| Source `.aep` / `.c4d` | snapshot | **Read + copy only**; never open for write |
| Receipt JSON | report / diff / shot | **Read only**; parsed by `/usr/bin/python3` |
| `--out` / shot dir | report, pack, snapshot | **Write** new files; no intentional overwrite of sources |
| Network | — | **None** in these scripts |
| Privilege | — | **User-level only**; no sudo |

Upstream MographJailed Protocol and AE/`c4dpy` scrapers are **out of scope** for this file except where the CLI invokes them by path discovery (describe only).

---

## 2. Blast radius (what can go wrong if misused or compromised)

### 2.1 Maximum impact if the user runs the tool as themselves

| Impact | Possible? | How |
|--------|-----------|-----|
| Delete or alter source `.aep`/`.c4d` | **Designed no** | Snapshot refuses existing dest; copies only |
| Delete arbitrary files | **No** `rm` in scripts | — |
| Remote code execution via network | **No** curl/wget/sockets | — |
| Privilege escalation | **No** sudo/setuid | — |
| Write large data / fill disk | **Yes** | Snapshot copies full project; pack tarball; repeated reports |
| Write outside intended folder | **Yes if user passes hostile `--out`** | e.g. `--out /Users/victim/Desktop` |
| Read sensitive files into report | **Yes if user points `--ingest` at them** | JSON load; content may embed in HTML |
| Execute attacker-controlled shell from receipts | **Low by design** | Python uses `json.load` + string inject into HTML, not `eval` of receipt as code |
| HTML/JS XSS if report opened | **Local file** | Payload is JSON embedded in script; treat report as **untrusted if receipts untrusted** |

### 2.2 Blast radius summary

| Zone | Radius |
|------|--------|
| **Source media / projects** | Minimal — read/copy only for allowed extensions |
| **Directories the user names** | Full write of *new* artifacts (report, tar, snapshots) |
| **System / other users** | None beyond normal same-uid filesystem rights |
| **Network** | None |
| **Secrets in environment** | Not printed deliberately; `describe` does not dump env |

**Headline:** Blast radius is **local filesystem under user control**, dominated by **disk fill** and **writing wherever `--out` / shot-dir points**, not by remote exploit or source-project destruction.

---

## 3. Attack surface inventory

### 3.1 Entry points

| Input | Commands | Sanitization today |
|-------|----------|--------------------|
| argv paths | all | Existence/type checks; extension allowlist on snapshot |
| `--out` directory | report, pack, snapshot | `mkdir -p`; no path jail |
| Receipt file contents | report, diff, shot | `json.load`; keys accessed as data |
| Shot directory tree | shot, pack | Glob `**/*.aep` / `**/*.c4d` (bounded counts on discover) |
| Template HTML | report | From repo path relative to script |

### 3.2 Dangerous primitives (checklist)

| Primitive | Present? | Notes |
|-----------|----------|--------|
| `eval` | **No** | — |
| `source` / `.` of user files | **No** | — |
| Network fetch | **No** | — |
| `rm` / `rm -rf` | **No** | — |
| `chmod` / `chown` | **No** | — |
| `sudo` | **No** | — |
| Unquoted `$user` in command position | Avoided for core ops | Review still advised on array loops |
| `PATH` prepend | **No** | Prefer absolute `/bin` `/usr/bin` |
| Python `eval` / `exec` on receipt | **No** | `json.load` only |
| Shell interpolation of receipt into `zsh -c` | **No** | — |

### 3.3 Code execution paths that *do* exist

1. **`/usr/bin/python3` heredoc** in `report` / `diff` — fixed script text; receipt data is JSON, not code.  
2. **`/bin/zsh -f mj-snapshot.zsh`** — fixed path under repo `tools/`.  
3. **HTML report** — browser executes embedded JS when user opens the file; data from receipts is inserted as JSON. Malicious receipt could attempt XSS in local HTML context.

---

## 4. Finding register (severity for same-user threat model)

| ID | Severity | Finding | Mitigation today | Residual risk |
|----|----------|---------|------------------|---------------|
| F1 | **Medium** | `--out` is not jailed; can write anywhere the user can | User chooses path | Accidental overwrite of *other* user files if dest exists and code path allows (report overwrites `mj-health-report.html` in `--out`) |
| F2 | **Medium** | `report` **overwrites** `$outdir/mj-health-report.html` and `HEALTH.txt` | Documented | Repeated runs clobber previous report in same dir |
| F3 | **Low** | Snapshot dest collision refuses overwrite; good | `-e` check | Race if two processes same timestamp+hash (unlikely) |
| F4 | **Low** | `pack` copies receipts/snapshots into stage then tar | No delete of sources | Can duplicate large data |
| F5 | **Low** | Fallback to bare `cp`/`python3` if absolute path missing | Unusual on Sequoia | PATH hijack only if absolute binaries gone and attacker controls PATH |
| F6 | **Low** | HTML embeds receipt strings | JSON encoding via `json.dumps` | XSS if encoding broken; keep using `json.dumps` |
| F7 | **Info** | `shot` recursive globs | Cap 20 files listed | Slow on huge trees; not RCE |
| F8 | **Info** | No integrity check that template is signed | Repo trust | Supply-chain of the git checkout |
| F9 | **Info** | AE/`c4dpy` not invoked by default | User runs hosts | Separate attack surface in Adobe/Maxon |

### Overwrite policy (explicit)

| Artifact | Overwrite? |
|----------|------------|
| Source `.aep` / `.c4d` | **Never** |
| Snapshot target if exists | **Refuse** |
| `mj-health-report.html` in `--out` | **Yes** (same name) |
| Hand-off tarball name | Unique timestamp |
| Pack stage dir | Unique timestamp |

---

## 5. Red-team test plan (reproducible)

Run on a disposable directory; do not aim at production shot trees.

### 5.1 Negative tests (should not destroy sources)

```zsh
# 1. Snapshot must not alter source mtime/size meaningfully beyond atime
SRC=/tmp/mj-rt/sample.aep
mkdir -p /tmp/mj-rt && echo fake > "$SRC"
BEFORE=$(stat -f '%m %z' "$SRC" 2>/dev/null || stat -c '%Y %s' "$SRC")
/bin/zsh -f tools/mj-snapshot.zsh "$SRC" --out /tmp/mj-rt/vers
AFTER=$(stat -f '%m %z' "$SRC" 2>/dev/null || stat -c '%Y %s' "$SRC")
# Expect: size unchanged; content identical

# 2. Second snapshot same bytes → SKIP, still one logical copy set
/bin/zsh -f tools/mj-snapshot.zsh "$SRC" --out /tmp/mj-rt/vers

# 3. Refuse non .aep/.c4d
echo x > /tmp/mj-rt/x.txt
/bin/zsh -f tools/mj-snapshot.zsh /tmp/mj-rt/x.txt   # expect error
```

### 5.2 Path / write tests

```zsh
# 4. Report only writes under --out
/bin/zsh -f tools/mj-observe.zsh report \
  --ingest docs/fixtures/sample-ingest.MJ_PROJECT_SUMMARY_1.json \
  --out /tmp/mj-rt/out
# Expect: only mj-health-report.html + HEALTH.txt under /tmp/mj-rt/out

# 5. Hostile-looking filename as ingest (should fail closed or parse fail, not shell out)
# Create file named ';id.json' and pass as --ingest — must not run id(1)
```

### 5.3 Receipt / HTML tests

```zsh
# 6. Oversized or invalid JSON → python exception, non-zero, no partial silent success claim
echo 'not-json' > /tmp/mj-rt/bad.json
/bin/zsh -f tools/mj-observe.zsh report --ingest /tmp/mj-rt/bad.json --out /tmp/mj-rt/out2

# 7. Open report in browser only if you accept local HTML trust model
```

### 5.4 Static audit commands

```zsh
/bin/zsh -n tools/mj-observe.zsh
/bin/zsh -n tools/mj-snapshot.zsh
grep -nE 'eval |sudo |curl |wget |rm -|chmod |source ' tools/*.zsh
```

---

## 6. Recommendations (priority)

| P | Action |
|---|--------|
| P1 | Document clearly: **`--out` overwrites** `mj-health-report.html` / `HEALTH.txt` |
| P1 | Keep **no `rm`**, **no network**, **no `eval`** as hard CI greps |
| P2 | Optional `--out` must-be-under prefix (shot-dir jail) for `shot`/`pack` |
| P2 | Refuse report `--out` that is not a directory already owned/writable by user (already implicit) |
| P3 | Content-Security-Policy meta in HTML template (defense in depth for local XSS) |
| P3 | `zsh -n` in TEST_CHECKLIST / CI |
| P3 | Do not fall back to PATH if absolute adapter missing — fail closed instead |

---

## 7. Claims a red team can falsify

If any of these become false, treat as a **security regression**:

1. Scripts contain **no** `eval`, `sudo`, `curl`, `wget`, `rm`.  
2. Snapshot **never** opens the source for write and **refuses** existing destination path.  
3. No network APIs are called from these two tools.  
4. Receipt data is not passed to `zsh -c` / `bash -c`.  
5. Python side uses `json.load` / `json.dumps`, not `eval`.  
6. Default operation does not require admin rights.

---

## 8. Related docs

- [ZSH_HARDENING.md](ZSH_HARDENING.md) — options and fixed adapters  
- [STOCK_ZSH_BASELINE.md](STOCK_ZSH_BASELINE.md) — ship low  
- Upstream MographJailed — Protocol allowlist (separate trust boundary)

---

*Auditable snapshot of design intent for Observer shell tools. Re-run the test plan after any change that adds writes, subprocesses, or path handling.*
