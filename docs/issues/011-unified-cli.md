# Issue 11 — Unified CLI `mj-observe`

**Priority:** P1  
**See:** [SCOPE_DASHBOARD_AND_TOOLS.md](../SCOPE_DASHBOARD_AND_TOOLS.md)

## Summary

Ship `tools/mj-observe.zsh` as the single stock entry: `describe`, `report`, `diff`, `pack`, `shot`.

## Acceptance

- [x] Skeleton with help / describe / report / diff / pack / shot  
- [ ] Qualify on Sequoia without Homebrew  
- [ ] `shot` discovers `.aep`/`.c4d` and aggregates receipts  
- [ ] Document AE / c4dpy invoke one-liners in README  

## Notes

Phase 1 orchestrates receipts; does not embed Adobe/Maxon automation.
