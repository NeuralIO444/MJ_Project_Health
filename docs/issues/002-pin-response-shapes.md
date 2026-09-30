# Issue 2 — Pin and document real `project.ingest` / `expression.lint` response shapes

**Labels:** `bug`, `integration`, `documentation`  
**Priority:** P0  
**Milestone:** v0.1 reliable  
**Blocks:** accurate health report, Issues 5–6 (report file / missing lists)

---

## Summary

`MJ_Project_Health.jsx` guesses response field names that do **not** match upstream MographJailed Tier 0 contracts. The report can show `?` for counts and miss lint findings even when the CLI succeeds.

Authoritative shapes are now documented in [`docs/RESPONSE_SHAPES.md`](../RESPONSE_SHAPES.md) from upstream `src/modules/project.zsh`.

---

## Problem

Current script logic (broken against real CLI):

```js
// WRONG keys
d.compCount / d.layerCount / d.expressionCount / d.fontCount / d.footageCount
d.missingFootageCount
d.footage[].missing          // ingest does not return footage[]

// WRONG lint keys
lint.data.findings || lint.data.issues || lint.data.problems
```

Real ingest keys: `numComps`, `numLayers`, `numExpressions`, `numFonts`, `numFootage`, `footageMissing[]`, `footageUnlinked[]`, …

Real lint keys: `findings[]` with `{ code, severity, comp, layer, propertyPath, message }`, plus `errors` / `warnings` / `info` counts.

---

## Scope (this issue only)

### In scope

1. **Document** — keep `docs/RESPONSE_SHAPES.md` accurate (done as starting point; update if upstream drifts).
2. **Fix script** — map report lines to real fields only.
3. **Status rules** — align PASS / WARNINGS / BLOCKERS with real signals:
   - BLOCKERS: `footageMissing.length > 0` **or** lint `errors > 0`
   - WARNINGS: lint `warnings > 0` **or** `footageUnlinked.length > 0`
   - PASS: otherwise
4. **Lint summary** — use `findings[].message` (and optionally `code` / `severity`); cap display at 12; show totals from `numFindings` / `errors` / `warnings`.
5. **Fixtures** — add minimal synthetic JSON under `docs/fixtures/`:
   - `sample-scrape.MJ_PROJECT_SCRAPE_1.json` (tiny valid scrape)
   - `sample-ingest.MJ_PROJECT_SUMMARY_1.json` (example `data` object)
   - `sample-lint.MJ_EXPRESSION_LINT_1.json` (example `data` with one E001 + one W001)
6. **Tests doc** — update `docs/TEST_CHECKLIST.md` with “counts match fixture field names” and “lint messages appear”.

### Out of scope (separate issues)

- Auto-select newest receipt (Issue 1)
- CLI path discovery (Issue 3)
- Writing `.health.txt` (Issue 5)
- Full missing-footage path list UI beyond names already in `footageMissing` (Issue 6 can extend)
- Calling real CLI in CI (no Mac runner assumed here)

---

## Implementation checklist

- [ ] `ae/MJ_Project_Health.jsx` uses only documented keys from RESPONSE_SHAPES.md
- [ ] Remove fallbacks for `compCount`, `issues`, `problems`, `missingFootageCount`
- [ ] Status uses `footageMissing` / `footageUnlinked` / lint `errors` / `warnings`
- [ ] Truncation notes use `compsTruncated`, `footageTruncated`, `findingsTruncated`
- [ ] Fixtures committed under `docs/fixtures/`
- [ ] TEST_CHECKLIST updated
- [ ] Manual smoke: designer-install CLI + real scrape still produces non-`?` counts

---

## Acceptance criteria

1. On a successful ingest against a real or fixture-shaped response, the alert shows numeric comps/layers/expressions/fonts/footage (not `?`).
2. When `footageMissing` is non-empty, status is **BLOCKERS** and missing count equals `footageMissing.length`.
3. When lint returns findings, at least one `message` is visible in the alert.
4. `docs/RESPONSE_SHAPES.md` matches upstream `project.zsh` for the fields we consume.
5. No new runtime dependencies; still Protocol v1 allowlisted ops only.

---

## References

- Upstream: `src/modules/project.zsh` — `handle_project_ingest`, `handle_expression_lint`
- Upstream: `docs/MJ_PROJECT_SCRAPE_1.md` (scrape input schema)
- Upstream: `docs/TIER0_OBSERVER.md`
- Local: `docs/RESPONSE_SHAPES.md`, `ae/MJ_Project_Health.jsx`
