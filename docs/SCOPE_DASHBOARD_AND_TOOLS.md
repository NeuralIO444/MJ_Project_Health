# Scope: Dashboard, unified CLI, and high-impact Observer tools

**Date:** 2026-09-30  
**Baseline:** [STOCK_ZSH_BASELINE.md](STOCK_ZSH_BASELINE.md) — ship stock zsh + host apps only.  
**Requested set:** Full GUI dashboard · #11 Unified CLI · #15 Self-describe · #9 Plugin footprint · #5 Expression risk map · #1 Shot Health · #2 Hand-off Pack · #3 Health Diff

---

## 0. GUI decision (critical)

| Option | Fits jail? | Choice |
|--------|------------|--------|
| Electron / native Swift app | **No** — not stock Sequoia, install burden | Out of scope |
| Local web server + Node | **No** | Out of scope |
| **Self-contained HTML report** opened with stock `open` | **Yes** | **In scope** |

**“Full GUI dashboard” in this product** means:

- Generate one **offline HTML file** from receipts (embedded CSS, no CDN required at view time if inlined).
- Open via `/usr/bin/open report.html` (Safari/WebKit).
- Optional: refresh by re-running the CLI (no live websocket).

Looks like a dashboard; runs on a locked Mac.

---

## 1. Item scopes

### #11 — Unified CLI `mj-observe`

**In**

```text
tools/mj-observe.zsh <command> [args]
  shot <dir>           Discover .aep / .c4d; run available health paths; write receipts
  report <receipts-dir> Build HTML + HEALTH.txt from existing receipts
  pack <dir>           Hand-off archive
  diff <old.json> <new.json>
  describe             Protocol / local capability probe
  help
```

**Out**

- Installing or launching AE/C4D GUI automation beyond documented scrape scripts  
- Network calls  

**Degrade cleanly:** no C4D → skip C4D; no AE → skip AE; print what ran.

---

### #15 — Protocol self-describe consumer

**In**

- If MographJailed CLI present: call `system.describe` (or equivalent) and print available ops.  
- Always: probe stock tools (`command -v sips jq avmediainfo …`) and host binaries (AE not probeable easily; `c4dpy` path glob).  
- Output: human table + optional JSON.

**Out**

- Claiming ops that are not allowlisted.

---

### #9 — Plugin / effect footprint (AE)

**In**

- From existing scrape / ingest data: unique effect names, font list, counts.  
- Section in HTML + `HEALTH.txt`.  
- No new AE DOM writes.

**Out**

- Full `plugin.audit` machine scan unless upstream op available and user opts in.

**Depends on:** scrape fields for effects/fonts (already in Tier 0 scrape design).

---

### #5 — Expression risk map (AE)

**In**

- Consume `expression.lint` findings + expression counts.  
- Rank: errors first, then warnings, then info; surface top N with code/comp/layer/message.  
- Optional: weight long expressions / known trap codes (W001 sampleImage+loop).  

**Out**

- Auto-fix expressions.

**Depends on:** Issue 2 field mapping (`findings[]`, severities).

---

### #1 — Shot Health (one command)

**In**

- `mj-observe shot <dir>`:
  - Find `*.aep` / `*.c4d` (bounded depth).
  - Instructions or hooks for AE scrape + `c4dpy` scrape (hosts must run scrapers; CLI aggregates).
  - Storage preflight (`df`).
  - Status rollup PASS / WARNINGS / BLOCKERS.
  - Write receipts under `<dir>/mj-receipts/` or user path.

**Reality on limited Mac:** AE JSX and `c4dpy` must be invoked by the user or via documented one-liners; the stock CLI **orchestrates and reports**, it does not embed Adobe/Maxon.

**Phase 1 (this build):** aggregate **existing** receipts + disk + capability describe.  
**Phase 2:** document exact AE / c4dpy invoke lines; optional `osascript` only if ever allowlisted upstream (not default).

---

### #2 — Hand-off Pack

**In**

```text
mj-observe pack <shot-dir>
  → mj-handoff-<name>-<timestamp>.tar.gz  (or folder)
     HEALTH.txt
     report.html
     receipts/*.json
     snapshots/  (if present; copy only, no overwrite sources)
     MACHINE.txt  (sw_vers, df summary)
```

**Out**

- Uploading to cloud; encrypting (optional later).

---

### #3 — Health Diff

**In**

- Diff two summary JSON files (ingest and/or lint and/or c4d summary).  
- Report: new missing, resolved missing, finding count delta, status change.

**Out**

- Semantic git diff of binary `.aep`.

---

## 2. Build phases in this repo

| Phase | Deliverables |
|-------|----------------|
| **P0 (this commit)** | Scope doc; `tools/mj-observe.zsh` skeleton (help, describe, report, diff, pack stubs); `web/dashboard_template.html`; issue drafts |
| **P1** | Issue 2 script fix; real report builder from fixtures |
| **P2** | C4D scrape schema + c4dpy stub; shot discovery |
| **P3** | Full HTML from multi-receipt; hand-off tarball; risk map + footprint sections |

---

## 3. Acceptance (dashboard + CLI)

1. `tools/mj-observe.zsh help` prints commands.  
2. `describe` lists stock tool presence without failing hard.  
3. `report` with fixtures produces HTML openable offline.  
4. `diff` on two fixture summaries prints a readable delta.  
5. No Homebrew/Node required to run tools.  
6. GUI = HTML file only.

---

## 4. Non-goals

- Electron, Tauri, SwiftUI app distribution  
- Background daemon UI  
- Mutating projects or auto-relink  
- Replacing Cineware  

---

*Scoped 2026-09-30 for MJ Project Health.*
