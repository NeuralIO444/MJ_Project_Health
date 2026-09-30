# Schema: MJ_C4D_SCRAPE_1

Parallel to `MJ_PROJECT_SCRAPE_1` for Cinema 4D Observer scrapes.
Produced by a read-only `c4dpy` script; consumed by summary tooling / future `c4d.ingest`.

## Envelope

Top-level JSON object. No Protocol wrapper here — this is the **receipt** written to disk (same role as AE `.scrape.json`).

## Required fields

| Field | Type | Notes |
|-------|------|--------|
| `schema` | string | Must be `"MJ_C4D_SCRAPE_1"` |
| `scraperVersion` | string | e.g. `"0.1.0"` |
| `projectPath` | string | Absolute path to the `.c4d` |
| `projectName` | string | Leaf filename |
| `scrapedAt` | string | ISO-8601 timestamp |
| `c4dVersion` | string | Application version if available |
| `assets` | array | Asset records (may be empty) |
| `assetsMissing` | array of string | Names or paths not found |
| `numAssets` | number | `len(assets)` |
| `numMissing` | number | `len(assetsMissing)` |
| `sourceUnchanged` | boolean | Always `true` for Observer scrape |

## Asset object

| Field | Type | Notes |
|-------|------|--------|
| `name` | string | Display / asset name |
| `path` | string | Resolved filesystem path when known; may be empty |
| `exists` | boolean | On-disk check at scrape time |
| `kind` | string | e.g. `texture`, `hdr`, `cache`, `xref`, `other`, `unknown` |
| `sizeBytes` | number \| null | Optional `stat` size |

## Optional fields

| Field | Type | Notes |
|-------|------|--------|
| `assetsTruncated` | boolean | Hit enumeration cap |
| `fps` | number | Document FPS if cheap to read |
| `frameFrom` / `frameTo` | number | Range if available |
| `notes` | string | Non-fatal scrape notes |

## Bounds (recommended)

- Max assets enumerated: **2000** (then set `assetsTruncated`)
- Path strings truncated to **512** chars if needed
- Total JSON soft target under **~8 MB** (align with AE observe max)

## Status mapping (consumer)

| Status | Condition |
|--------|-----------|
| **BLOCKERS** | `numMissing > 0` |
| **WARNINGS** | Soft issues only (future) |
| **PASS** | `numMissing === 0` |

## Non-goals

- Relinking assets  
- Writing the `.c4d`  
- Opening GUI managers  
- Full node graph dump  

## Producer

`integrations/cinema4d/scene_health.py` via `c4dpy` (see README in that folder).
