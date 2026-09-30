# Research report: Stock macOS Sequoia capabilities and Cinema 4D expansion

**Date:** 2026-09-29  
**Context:** Limited / locked-down Mac (no admin, no Homebrew, no Xcode CLT required at runtime).  
**Goal:** Inventory native Sequoia tools useful for motion-graphics pipelines, define what helpers can ship under those constraints, and expand the Observer model from After Effects to Maxon Cinema 4D.

**Related package:** MJ Project Health (AE Tier 0 Observer consumer of [MographJailed](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI)).

---

## 1. Executive summary

A stock macOS Sequoia install already provides enough primitives to build **read-only project health, asset verification, media inspection, and non-overwrite versioning** without package managers or compilers.

After Effects is covered by ExtendScript + a thin native protocol (MographJailed).  
Cinema 4D is covered by **`c4dpy`** (headless C4D + Python API shipped with the app) plus the same stock macOS adapters.

Highest return remains the same pattern already used for AE:

```text
Host app scrape (read-only) → structured JSON receipt → stock zsh / Protocol v1 → PASS | WARNINGS | BLOCKERS
```

Never mutate source media or project files in the Observer tier.

---

## 2. Assumptions and constraints

| Assumption | Implication |
|------------|-------------|
| macOS Sequoia (15.x) or recent Sonoma+ | `jq` available on Sequoia; `avmediainfo` since Big Sur |
| No sudo / no admin | User-level installs only (`~/Documents`, LaunchAgents in `~/Library`) |
| No Homebrew / MacPorts / pip runtime | Production helpers use `/bin` and `/usr/bin` only |
| No Xcode CLT required at runtime | Compilers optional for *development*; not for shipped tools |
| AE 2024+ optional | JSX + `system.callSystem` |
| Cinema 4D optional | Requires existing C4D install + valid license for `c4dpy` |
| Network volumes | Fail closed for automatic mutation/index paths |

---

## 3. Stock Sequoia “loot” (no extra install)

### 3.1 High value for motion graphics

| Category | Binaries | Pipeline use |
|----------|----------|--------------|
| Shell | `/bin/zsh`, `awk`, `sed`, `grep`, `cut`, `sort`, `uniq` | Runners, reports, log parsing |
| Files / identity | `stat`, `file`, `find`, `cp`, `mv`, `mkdir`, `mktemp`, `ditto`, `shasum` | Manifests, hashes, non-overwrite copies, APFS-aware packaging |
| Images | `sips` | Dimensions, format, DPI; resize/convert without ImageMagick |
| Media | `avmediainfo`, `avconvert`, `afinfo`, `afconvert` | Duration, tracks, codecs, dimensions, nominal FPS; light derivatives |
| Structured data | `plutil`, `sqlite3`, **`jq` (Sequoia+)** | JSON/plist validation, small local stores, envelope shaping |
| Metadata | `mdls`, `mdfind`, `xattr` (read) | Advisory search, tags, provenance *names* only |
| System | `sw_vers`, `uname`, `df`, `system_profiler` | Version, arch, free space, inventory |
| Automation | `osascript` (JXA) | Fixed audited bridges only (e.g. AVFoundation frame path) |
| Python (stock) | `/usr/bin/python3` | Local parsers (as used by upstream Tier 0 ingest/lint) |

### 3.2 Explicitly out of scope for production runtime

- FFmpeg, ImageMagick, OpenCV  
- Node / npm, Homebrew formulas  
- Generic “run any shell” or arbitrary SQL APIs  
- Background daemons that require admin  

Xcode Command Line Tools remain **optional** (dev/QA only), not a production dependency.

### 3.3 Sequoia-specific note

`jq` on Sequoia reduces the need for embedded JSON parsers in shell reports and makes receipt post-processing simpler while staying stock.

---

## 4. What tools can be built under these constraints

| Tool | Host | Stock pieces | Return |
|------|------|--------------|--------|
| **Project Health** (AE) | After Effects | JSX scraper + Protocol v1 `project.ingest` / `expression.lint` | Highest for AE — missing footage + expression defects |
| **Scene Health** (C4D) | Cinema 4D | `c4dpy` + asset API + zsh/jq report | Highest for C4D — missing textures/caches/XRefs |
| **Asset manifest + verify** | AE / C4D / files | `stat`, `shasum`, path existence | Pre-render integrity |
| **Non-overwrite snapshot** | `.aep` / `.c4d` | `shasum` + `cp` (APFS clone when available) | Version safety |
| **Texture / image probe** | Linked bitmaps | `sips` | DPI, size, format before farm |
| **Media timing probe** | Footage | `avmediainfo` | Duration / track facts (local-only) |
| **Storage preflight** | Any output path | `df` + local/network classification | Fail before disk-full or network write |
| **Hand-off pack** | Shot folder | Shared receipts + text summary | AE + C4D in one artifact |

Shared architecture:

```text
Host scrape (read-only)
  → JSON receipt (versioned schema)
  → Native runner (MographJailed Protocol v1 and/or thin zsh)
  → Stock adapters only
  → JSON envelope + human report
```

---

## 5. Cinema 4D expansion

### 5.1 Why C4D is different from AE

| | After Effects | Cinema 4D |
|--|---------------|-----------|
| External automation | ExtendScript + `system.callSystem` | **`c4dpy`** (headless app + full Python API) |
| Scene file | Opaque without AE | Opaque without C4D — **must** use API |
| Missing-asset data | Footage items + scraper | `c4d.documents.GetAllAssetsNew` (Project Asset Inspector data) |
| Extra runtime on limited Mac | None (stock zsh) | Requires C4D install + license |

`c4dpy` is not stock macOS; it ships with Cinema 4D. On a machine that already runs C4D, it is the correct zero-extra-install automation surface.

### 5.2 Typical macOS path

```text
/Applications/Maxon Cinema 4D <version>/c4dpy.app/Contents/MacOS/c4dpy
```

Invoke with an absolute path to a Python script; use `sys.argv` for arguments. GUI APIs are unavailable (headless).

### 5.3 API hooks for Observer tools

- `c4d.documents.LoadDocument` — open scene without GUI  
- `c4d.documents.GetAllAssetsNew` — asset list with existence flags (prefer over deprecated `GetAllAssets`)  
- Optional later: `SaveProject` only under explicit user-tier “collect assets” flows (not Observer default)

### 5.4 Proposed C4D receipt schema (draft)

**`MJ_C4D_SCRAPE_1`** (parallel to `MJ_PROJECT_SCRAPE_1`):

| Field | Purpose |
|-------|---------|
| `schema` | `"MJ_C4D_SCRAPE_1"` |
| `scraperVersion` | Script version |
| `projectPath` / `projectName` | Scene identity |
| `scrapedAt` | ISO timestamp |
| `c4dVersion` | Application version string |
| `assets[]` | `{ name, path, exists, kind, sizeBytes? }` |
| `assetsMissing[]` | Names/paths not found |
| `numObjects` / other light counts | Optional scene stats |
| Truncation flags | If lists are capped |

Downstream summary op (conceptual): `c4d.ingest` → `MJ_C4D_SUMMARY_1` with counts + missing lists, same status vocabulary as AE.

### 5.5 Ranked C4D tools

| Rank | Tool | Notes |
|------|------|-------|
| 1 | **C4D Scene Health** | Missing assets + counts via `c4dpy` |
| 2 | **Asset manifest + verify** | Disk check + optional hash on resolved paths |
| 3 | **Non-overwrite `.c4d` snapshot** | File-level; no C4D required |
| 4 | **Texture probe** | `sips` on image assets from receipt |
| 5 | **Pre-render gate** | Storage + missing count |
| 6 | **AE↔C4D hand-off report** | Combined receipts for mixed shows |

### 5.6 Limits and non-goals (v1)

- No auto-relink  
- No in-place project mutation  
- No dependency on Redshift/third-party plugins beyond reporting what the API exposes  
- Degrade cleanly if `c4dpy` is missing (clear UNSUPPORTED / not-found message)  
- License/login issues are environmental — document, do not paper over  

---

## 6. Unified Observer product (AE + C4D)

| Layer | After Effects | Cinema 4D |
|-------|---------------|-----------|
| Scrape | JSX → `MJ_PROJECT_SCRAPE_1` | `c4dpy` → `MJ_C4D_SCRAPE_1` |
| Native | MographJailed Protocol v1 | Same runner and/or thin zsh+jq path |
| Report | `MJ_Project_Health.jsx` | `C4D_Scene_Health` entry (script or shell) |
| Snapshot | `project.snapshot` | File snapshot of `.c4d` |
| Shared | Storage preflight, `sips` / `avmediainfo`, receipt folder, PASS/WARNINGS/BLOCKERS | Same |

One receipts directory, one status language, one safety rule: **observe only**.

---

## 7. Environment split: design sandbox vs target Mac

| This design environment | User’s Sequoia Mac |
|-------------------------|-------------------|
| Schemas, zsh runners, docs, fixtures, issues | Execute AE JSX, `c4dpy`, `sips`, `avmediainfo` |
| Git packaging | Real scrapes and qualification |
| Cannot run AE or Cinema 4D | Full end-to-end health checks |

Design and specify here; qualify on hardware that has AE and/or C4D.

---

## 8. Recommended build order

1. **AE Issue 2** — Pin health script to real `MJ_PROJECT_SUMMARY_1` / `MJ_EXPRESSION_LINT_1` fields (unblocks trustworthy AE reports).  
2. **C4D Scene Health v0** — `c4dpy` scraper + `MJ_C4D_SCRAPE_1` + missing-asset report.  
3. **Shared media/texture probe** — `sips` / `avmediainfo` on paths from either receipt.  
4. **Unified snapshot** — non-overwrite copies for `.aep` and `.c4d`.  
5. **Hand-off pack** — one shot-folder summary combining AE + C4D receipts.

---

## 9. Hard rules (carry forward)

1. No sudo, no Homebrew, no FFmpeg/Node as production runtime dependencies.  
2. No source mutation; derivatives never overwrite.  
3. Network / unknown volumes fail closed for automatic paths.  
4. Prefer allowlisted operations and versioned receipt schemas.  
5. C4D features optional: fail closed with a clear message if `c4dpy` is absent.  
6. JXA / AppleScript only behind fixed, audited adapters — never as a general execution surface.

---

## 10. References

### macOS stock tools

- SS64 macOS command index: https://ss64.com/mac/  
- Apple `sips`, `plutil`, `avmediainfo` / media tools (system man pages)  
- Sequoia addition of `jq` as a stock utility (community / ops write-ups, 2025+)

### MographJailed / AE Observer

- https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI  
- Upstream `docs/MJ_PROJECT_SCRAPE_1.md`, `docs/TIER0_OBSERVER.md`, `src/modules/project.zsh`  
- This package: `docs/RESPONSE_SHAPES.md`, `docs/DESIGN.md`

### Cinema 4D

- c4dpy manual (Maxon Python SDK): headless interpreter, macOS package path  
- `c4d.documents.GetAllAssetsNew` — asset enumeration for Project Asset Inspector–class data  
- Maxon command-line / Team Render docs — separate from Observer (render is Tier 1+)  
- Official Python API examples: https://github.com/Maxon-Computer/Cinema-4D-Python-API-Examples  

---

## 11. Appendix — status vocabulary (shared)

| Status | AE signal | C4D signal |
|--------|-----------|------------|
| **PASS** | No missing footage; no lint errors | No missing assets |
| **WARNINGS** | Lint warnings; unlinked footage | Soft path issues; non-fatal asset warnings |
| **BLOCKERS** | Missing footage; lint errors | Missing textures/caches/XRefs required for render |

---

*Report drafted for the MJ Project Health repository to guide AE completion and C4D expansion under limited-macOS constraints.*
