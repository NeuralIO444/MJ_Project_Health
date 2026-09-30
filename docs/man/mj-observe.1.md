# mj-observe(1) — MographJailed Observer CLI

**Version:** 0.2.0-dev  
**Baseline:** stock macOS Sequoia `/bin/zsh` + `/usr/bin` (no Homebrew)

```
mj-observe <command> [options]
```

Read-only project health for After Effects and Cinema 4D. Builds offline HTML reports from receipts. Never mutates `.aep`, `.c4d`, or source media.

---

## SYNOPSIS

```
mj-observe help
mj-observe describe [--json]
mj-observe report [--ingest FILE] [--lint FILE] [--c4d FILE] [--out DIR]
mj-observe diff OLD.json NEW.json
mj-observe pack SHOT_DIR [--out DIR]
mj-observe shot SHOT_DIR
mj-observe snapshot FILE.aep|FILE.c4d [--out VERSIONS_DIR]
```

---

## DESCRIPTION

**mj-observe** is the unified entry point for the MJ Project Health Observer.

| Role | Tool |
|------|------|
| Host scrape (AE) | `ae/MJ_Project_Health.jsx` + MographJailed Protocol |
| Host scrape (C4D) | `c4dpy integrations/cinema4d/scene_health.py` |
| Aggregate / report | **mj-observe** (this command) |
| Non-overwrite copy | **mj-observe snapshot** → `mj-snapshot.zsh` |

Status vocabulary:

| Status | Meaning |
|--------|---------|
| **PASS** | No missing AE footage/C4D assets; no lint errors |
| **WARNINGS** | Lint warnings and/or unlinked AE footage |
| **BLOCKERS** | Missing footage/assets and/or lint errors |

Dashboard output is a single **offline HTML** file (no Electron, no server). Open with stock `open`.

---

## COMMANDS

### help

Print this synopsis (short form). For the full manual, open `docs/man/mj-observe.1.md`.

### describe [--json]

Probe this machine:

- Stock tools: `zsh`, `jq`, `sips`, `avmediainfo`, `plutil`, `shasum`, `df`, `python3`, …
- Hosts: `c4dpy` under `/Applications/Maxon Cinema 4D*`
- Optional: MographJailed CLI at `~/Documents/MographJailed/dist/mograph-jailed.zsh`

`--json` is reserved for a machine-readable envelope (not fully expanded in 0.2.0-dev).

### report

Build `mj-health-report.html` + `HEALTH.txt` from receipt JSON.

| Option | File schema |
|--------|-------------|
| `--ingest` | `MJ_PROJECT_SUMMARY_1` (AE `project.ingest` data) |
| `--lint` | `MJ_EXPRESSION_LINT_1` (AE `expression.lint` data) |
| `--c4d` | `MJ_C4D_SCRAPE_1` (c4dpy scene scrape) |
| `--out DIR` | Output directory (default: `.`) |

At least one of `--ingest` or `--c4d` is required. Missing lists are merged; status is the worst of AE and C4D signals.

```zsh
mj-observe report \
  --ingest docs/fixtures/sample-ingest.MJ_PROJECT_SUMMARY_1.json \
  --lint   docs/fixtures/sample-lint.MJ_EXPRESSION_LINT_1.json \
  --c4d    docs/fixtures/sample-c4d.MJ_C4D_SCRAPE_1.json \
  --out    /tmp/mj-out
open /tmp/mj-out/mj-health-report.html
```

### diff

Compare two summary/scrape JSON files (bare data or Protocol `data` envelopes).

Prints:

- new missing / resolved missing (AE `footageMissing` or C4D `assetsMissing`)
- numeric field deltas (`numComps`, `numMissing`, `errors`, …)

```zsh
mj-observe diff yesterday.json today.json
```

### pack

Build a hand-off archive for a shot folder:

- `MACHINE.txt` — `sw_vers`, `df`
- `receipts/` — copies from `mj-receipts/` or `receipts/`
- `snapshots/` — copies from `mj-versions/` if present
- `HEALTH.txt` / `mj-health-report.html` if present
- `mj-handoff-<name>-<timestamp>.tar.gz`

```zsh
mj-observe pack /Shots/SH010 --out /Shots/SH010
```

### shot

One-shot orchestration for a directory:

1. Discover `*.aep` / `*.c4d` (bounded)
2. Run **describe**
3. Find receipts under `mj-receipts/` or `receipts/`
4. Auto-**report** when AE summary, lint, and/or C4D scrape JSON are present
5. Print **df** for the shot path

Does **not** launch AE or C4D; run host scrapers first and save receipts into the shot folder.

```zsh
mj-observe shot /Shots/SH010
```

### snapshot

Non-overwrite hash snapshot of a single `.aep` or `.c4d`. Delegates to `tools/mj-snapshot.zsh`.

```zsh
mj-observe snapshot /Shots/SH010/SH010.aep
mj-observe snapshot /Shots/SH010/SH010.c4d --out /Shots/SH010/mj-versions
```

See **mj-snapshot(1)** (`docs/man/mj-snapshot.1.md`).

---

## FILES

| Path | Role |
|------|------|
| `web/dashboard_template.html` | Offline HTML shell; report injects `window.MJ_DASHBOARD` |
| `docs/fixtures/*.json` | Sample AE + C4D receipts |
| `docs/RESPONSE_SHAPES.md` | AE ingest/lint field map |
| `docs/MJ_C4D_SCRAPE_1.md` | C4D scrape schema |
| `docs/STOCK_ZSH_BASELINE.md` | Ship stock; build high |

---

## EXIT BEHAVIOR

Commands print errors to stdout and return non-zero on hard failures (missing required files, hash failure). Soft misses (no `c4dpy`) are reported as `MISS` lines by **describe**, not fatal.

---

## SAFETY

- Observer only — no project save, no relink, no media rewrite  
- No sudo, no Homebrew runtime dependency  
- Network volumes: prefer local paths; storage probe is advisory (`df`)

---

## SEE ALSO

`mj-snapshot(1)`, `docs/AE_C4D_INTEGRATION.md`, `docs/SCOPE_DASHBOARD_AND_TOOLS.md`,  
[MographJailed](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI),  
[MJ_Project_Health](https://github.com/NeuralIO444/MJ_Project_Health)
