# After Effects ↔ Cinema 4D integration

**Date:** 2026-09-29  
**Context:** MographJailed as a dual-host Observer (AE + C4D) on limited macOS.  
**Companion docs:** [RESEARCH_SEQUOIA_C4D.md](RESEARCH_SEQUOIA_C4D.md), [DESIGN.md](DESIGN.md), [RESPONSE_SHAPES.md](RESPONSE_SHAPES.md)

This note separates **official Adobe/Maxon product integration** from the **MographJailed Observer layer**. The jail does not replace Cineware; it sits beside it.

---

## 1. Two layers

| Layer | Owner | Role |
|-------|--------|------|
| **Creative pipeline** | Adobe + Maxon | Cineware, Live Link, Extract, multipass, AEC |
| **Observer / evidence** | MographJailed | Health, missing assets/footage, snapshots, storage, shared reports |

```text
Official:  make the picture (3D in AE, multipass, cameras/nulls)
Jail:      prove the project and assets are fit to open, share, and render
```

---

## 2. Official AE ↔ C4D integration

### 2.1 Cineware (live `.c4d` in After Effects)

| Capability | Behavior |
|------------|----------|
| Import `.c4d` | Footage item + **Cineware** effect on the layer |
| In-comp render | CineRender / C4D engine from AE (draft vs final quality) |
| Extract | Cameras, lights, nulls (External Compositing tags) → AE 3D layers |
| Live Link | Synchronize AE and C4D timelines |
| Takes | Switch C4D Takes from Cineware |
| Edit Original | Open full C4D or C4D Lite on the linked file |
| New from AE | `File → New → Maxon Cinema 4D File` |
| Export AE → C4D | `File → Export → Maxon Cinema 4D Exporter` (text/shapes → extrudes; cameras/lights/nulls) |

**C4D Lite** ships with After Effects for basic 3D authoring. Full Cinema 4D unlocks the richer path.

**Limits**

- Third-party GPU renderers generally do **not** render inside Cineware; finishing usually uses multipass/EXR.
- Extract quality depends on External Compositing tags and Melange-related save prefs in C4D.
- Live Link depends on matching versions, prefs (`Live Link Enabled at Startup`), and port availability.

### 2.2 Multipass / AEC hand-off

```text
C4D Render Settings
  → Multi-Pass + Compositing Project File (.aec)
  → AE imports .aec
  → Comps with passes, camera, lights, nulls
```

Common passes: beauty, diffuse, specular, reflection, shadow, AO, object buffers, cryptomatte (renderer-dependent).

**Save Project with Assets** and relative paths keep other machines and farms reliable.

### 2.3 Typical mograph loop

```text
C4D: model / animate / External Compositing tags
        ↓
AE: Cineware layout + Extract cameras/nulls
        ↓
C4D: final multipass / Takes
        ↓
AE: grade, type, 2D FX, delivery
```

Match FPS, frame range, and color management across both apps. Prefer clean, unique object names.

### 2.4 References (product docs)

- Adobe: [Create Cinema 4D and Cineware files in After Effects](https://helpx.adobe.com/after-effects/using/c4d.html)
- Maxon: Cineware / After Effects integration help (versioned under help.maxon.net)
- Maxon: Project Asset Inspector (GUI counterpart to API asset enumeration)

---

## 3. Failure modes the official stack does not solve

| Failure | Typical cause |
|---------|----------------|
| Missing textures (C4D or Cineware) | Moved folders, absolute paths, incomplete “Save with Assets” |
| Empty / wrong Extract | Missing External Compositing tags; Melange prefs |
| Live Link broken | Prefs, port, version skew |
| Surprise AE renders | Draft vs Final; GPU renderer outside Cineware |
| Shot fails on another Mac | Unlinked footage, fonts, plugins, network volumes |
| Version chaos | Overwritten `.c4d` / `.aep` with no hash-backed copy |

Cineware does not audit disks, hash projects, or lint AE expressions. That is Observer work.

---

## 4. MographJailed dual-host model

```text
┌─────────────────┐     ┌─────────────────┐
│  Cinema 4D      │     │  After Effects  │
│  c4dpy scrape   │     │  JSX scrape     │
│  MJ_C4D_SCRAPE_1│     │  MJ_PROJECT_…   │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     ▼
            MographJailed Protocol v1
            (allowlisted, local-first, no source mutation)
                     │
         ┌───────────┼───────────┐
         ▼           ▼           ▼
    c4d.ingest  project.ingest  shared ops
    missing[]   expression.lint snapshot /
                                storage / sips
                     │
                     ▼
            PASS / WARNINGS / BLOCKERS
            + optional shot hand-off report
```

| Need | Official product | MographJailed |
|------|------------------|---------------|
| 3D in the AE timeline | Cineware | — |
| Cameras / nulls in AE | Extract | — |
| Multipass composite | AEC + EXR | — |
| “Is this `.c4d` safe?” | — | **C4D Scene Health** |
| “Is this `.aep` safe?” | — | **Project Health** |
| Missing textures / footage before farm | Manual inspectors | **Receipts + verify** |
| Non-destructive versions | Discipline | **Snapshots** |
| Shared shot checklist | Spreadsheets | **Unified report** |

`c4dpy` is the C4D-side scraper host (parallel to the AE JSX scraper). The **jail** remains the native protocol: fixed commands, structured args, local-only defaults.

---

## 5. Integration patterns to support

### Pattern 1 — Dual health (highest return)

Before Cineware work or a long render:

1. C4D Scene Health → `MJ_C4D_SCRAPE_1`  
2. AE Project Health → `MJ_PROJECT_SCRAPE_1` + ingest/lint  
3. One receipts folder → combined PASS / WARNINGS / BLOCKERS  

### Pattern 2 — Asset continuity

`c4dpy` lists texture paths → stock `sips` / existence / optional hash → AE confirms plates/footage. Same disk truth for both apps.

### Pattern 3 — Shot hand-off pack

Per shot folder:

- Hash-suffixed, non-overwrite snapshots of `.c4d` and `.aep`  
- Latest C4D + AE scrape receipts  
- Text report: missing assets, missing footage, expression errors, free space  

### Pattern 4 — Cineware prep checklist (advisory only)

Report, do not drive UI:

- FPS / duration mismatch signals from both scrapes  
- Naming / tag hints if exposed via API  
- Takes / output path presence when available  
- Local vs network project path  

### Pattern 5 — Post-render verify

After multipass write: storage preflight + file manifests on EXR/pass folders (stock tools only).

---

## 6. Explicit non-goals (Observer / jail)

- Driving Cineware UI or Live Link sockets  
- Replacing multipass or AEC export  
- Auto-relinking textures or footage  
- In-process control of AE from `c4dpy` or C4D from JSX  
- Homebrew / FFmpeg as production runtime dependencies  

Those remain Maxon/Adobe product features or explicit Tier-1 user actions.

---

## 7. Status vocabulary (shared)

| Status | AE signal | C4D signal |
|--------|-----------|------------|
| **PASS** | No missing footage; no lint errors | No missing assets |
| **WARNINGS** | Lint warnings; unlinked footage | Soft path issues; non-fatal warnings |
| **BLOCKERS** | Missing footage; lint errors | Missing textures/caches/XRefs needed for render |

---

## 8. Build sequence (AE + C4D under MographJailed)

| Phase | Deliverable | Location |
|-------|-------------|----------|
| 1 | AE Issue 2 — real ingest/lint field mapping | `ae/MJ_Project_Health.jsx`, [issues/002](issues/002-pin-response-shapes.md) |
| 2 | `MJ_C4D_SCRAPE_1` schema + minimal `c4dpy` scraper | `integrations/cinema4d/` (this package or upstream) |
| 3 | `c4d.ingest` (or thin summary) + Scene Health consumer | Protocol + consumer script |
| 4 | Shared snapshot, `sips` texture probe, storage preflight | Native / stock adapters |
| 5 | `shot-health` runner — both scrapes → one report | tools/ |

---

## 9. Draft C4D receipt (aligns with RESEARCH_SEQUOIA_C4D)

**`MJ_C4D_SCRAPE_1`** (parallel to `MJ_PROJECT_SCRAPE_1`):

| Field | Purpose |
|-------|---------|
| `schema` | `"MJ_C4D_SCRAPE_1"` |
| `scraperVersion` | Script version |
| `projectPath` / `projectName` | Scene identity |
| `scrapedAt` | ISO timestamp |
| `c4dVersion` | Application version |
| `assets[]` | `{ name, path, exists, kind, sizeBytes? }` |
| `assetsMissing[]` | Not found |
| Light scene counts | Optional |
| Truncation flags | If lists capped |

Scraper path: `c4dpy` → `LoadDocument` → `GetAllAssetsNew(..., allowDialogs=False)` → write JSON → quit. No GUI, no save unless a later explicit Tier-1 collect-assets flow.

---

## 10. Bottom line

| Question | Answer |
|----------|--------|
| Can AE and C4D integrate deeply? | **Yes** — Cineware, Extract, Live Link, multipass/AEC |
| Is that MographJailed’s job? | **No** — product UI and render |
| Can MographJailed serve that pipeline? | **Yes** — health, assets, versions, hand-off evidence |
| Does “mograph jailed” include C4D? | **Yes** — same jail, `c4dpy` as second host scraper |

Official stack makes the picture. The jail makes sure the **project and assets are fit** before and after.

---

*Captured from the MJ Project Health design conversation (2026-09-29) for repo continuity.*
