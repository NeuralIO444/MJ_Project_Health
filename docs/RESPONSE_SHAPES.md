# Response shapes — project.ingest & expression.lint

Authoritative fields from upstream MographJailed `src/modules/project.zsh`
(Tier 0 Observer). Protocol v1 envelope is unchanged; only `data` is documented here.

These shapes are what `MJ_Project_Health.jsx` must consume. Do not invent alternate key names.

## Protocol envelope (all commands)

```json
{
  "protocol": "MOGRAPHJAILED",
  "protocolVersion": 1,
  "cliVersion": "<string>",
  "requestId": "<string>",
  "command": "<string>",
  "ok": true,
  "data": { },
  "warnings": [],
  "error": null
}
```

On failure: `ok: false`, `data` absent/null, `error: { "code", "message", ... }`.

---

## `project.ingest` → `data`

**Schema id:** `MJ_PROJECT_SUMMARY_1`

| Field | Type | Notes |
|-------|------|--------|
| `schema` | string | `"MJ_PROJECT_SUMMARY_1"` |
| `projectPath` | string | Absolute path from scrape |
| `projectName` | string | Leaf filename |
| `scrapedAt` | string | ISO timestamp from scrape |
| `aeVersion` | string | AE version string |
| `numComps` | number | `len(comps)` |
| `numLayers` | number | Sum of layers across comps |
| `numExpressions` | number | Sum of expression records |
| `numEffects` | number | Sum of effect records |
| `numFonts` | number | Unique font count |
| `fonts` | string[] | Sorted unique font names |
| `numFootage` | number | Footage item count |
| `footageMissing` | string[] | Names flagged missing or path not on disk |
| `footageUnlinked` | string[] | Names with empty path |
| `layerTypes` | object | Map of layer type string → count |
| `compsTruncated` | boolean | Scrape hit comp cap |
| `footageTruncated` | boolean | Scrape hit footage cap |
| `sourceUnchanged` | boolean | Always true for this op (read-only) |

**Not present:** `compCount`, `layerCount`, `expressionCount`, `fontCount`, `footageCount`, `missingFootageCount`, `footage` array.

**Error codes (ingest path):** `INVALID_PATH`, `INVALID_TARGET`, `PERMISSION_DENIED`, `UNSUPPORTED`, `SCRAPE_TOO_LARGE`, `INVALID_JSON`, `SCHEMA_MISMATCH`, `INGEST_FAILED`, plus local-storage blocks from LocalFS.

---

## `expression.lint` → `data`

**Schema id:** `MJ_EXPRESSION_LINT_1`

| Field | Type | Notes |
|-------|------|--------|
| `schema` | string | `"MJ_EXPRESSION_LINT_1"` |
| `numExpressions` | number | Expressions examined |
| `numFindings` | number | Length of `findings` (after cap) |
| `errors` | number | Count severity === `"error"` |
| `warnings` | number | Count severity === `"warning"` |
| `info` | number | Count severity === `"info"` |
| `findings` | object[] | See finding object below |
| `findingsTruncated` | boolean | Hit max findings (default 200) |
| `rules` | string[] | `["E001","E002","W001","W002","W003","I001"]` |
| `sourceUnchanged` | boolean | Always true |

### Finding object

| Field | Type | Notes |
|-------|------|--------|
| `code` | string | Rule id |
| `severity` | string | `"error"` \| `"warning"` \| `"info"` |
| `comp` | string | Comp name |
| `layer` | string | Layer name |
| `propertyPath` | string | Property path |
| `message` | string | Human-readable |

### Rules (current)

| Code | Severity | Meaning |
|------|----------|---------|
| E001 | error | `thisComp.layer("…")` name not in comp |
| E002 | error | `effect("…")` name not on layer |
| W001 | warning | `sampleImage` inside `for`/`while` |
| W002 | warning | Hard-coded absolute path |
| W003 | warning | Expression text &gt; 2000 chars |
| I001 | info | Uses `eval(` |

**Not present:** `issues`, `problems` as alternate arrays.

---

## Health script mapping (target)

| Report line | Source field |
|-------------|--------------|
| Project | `data.projectName` |
| Comps | `data.numComps` |
| Layers | `data.numLayers` |
| Expressions | `data.numExpressions` |
| Fonts | `data.numFonts` (+ optional `data.fonts`) |
| Footage | `data.numFootage` |
| Missing | `data.footageMissing.length` (+ list names) |
| Unlinked | `data.footageUnlinked.length` |
| Lint status | `data.errors` / `data.warnings` / `data.findings` |
| Truncation notes | `compsTruncated`, `footageTruncated`, `findingsTruncated` |

Status rules (proposed):

- **BLOCKERS** if `footageMissing.length > 0` or `data.errors > 0`
- **WARNINGS** if `data.warnings > 0` or `footageUnlinked.length > 0`
- **PASS** otherwise
