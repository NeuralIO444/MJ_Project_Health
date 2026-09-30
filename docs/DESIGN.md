# Design notes — MJ Project Health

Captured from the scoping conversation (2026-09-29). Context: expand After Effects capability on a **limited / locked-down macOS** using only stock tools and the MographJailed native protocol.

## Problem

Corporate or limited Macs often block:

- Homebrew / MacPorts
- Python / Node / pip / npm
- Xcode Command Line Tools
- FFmpeg, OpenCV, daemons, local servers
- Admin / sudo

Motion-graphics artists still need reliable project health signals before long renders or hand-offs. Missing footage and expression bugs are the highest-cost failures and usually appear too late.

## Constraints (hard)

- Stock `/bin/zsh` only for the native side
- No public arbitrary shell or SQL
- Source media never mutated; derivatives never overwrite
- After Effects talks to native code only through Protocol v1 request files
- Fail closed on network / unknown storage
- Zero-install designer path preferred

## Solution pattern

```
AE (ExtendScript)
  → official read-only scraper → MJ_PROJECT_SCRAPE_1 receipt
  → Protocol v1 request file
  → /bin/zsh -f mograph-jailed.zsh --request …
  → project.ingest + expression.lint
  → JSON envelope
  → plain-text health report in AE
```

## Ranked tool list (highest return first)

Return = daily time saved × risk reduction × frequency of the pain, under the hard constraints above.

### Tier S

1. **Project Health / Observer** — scrape + ingest + lint summary  
   Catches missing footage and broken expressions before render/hand-off.
2. **Expression Linter** (depth) — static analysis of scraped expressions  
   Bugs that only surface at render time or on another machine.
3. **Non-destructive Auto-Snapshot** — hash + timestamped `.aep` copy (APFS clone when possible)  
   Version chaos and accidental overwrite prevention.

### Tier A

4. Missing footage / font / plugin audit pack  
5. Asset Manifest + Verify  
6. Storage Preflight  

### Tier B / later

7. Media Timing Probe (`avmediainfo`)  
8. Search Candidate (Spotlight, advisory only)  
9. Live Observe Dashboard  
10. Frame Extract (`media.frame` — qualification-gated)  
11. Image Stats / Compare  
12. NativeDB fixed-schema local indexes  

## Decisions for v1 of this package

| Decision | Choice | Rationale |
|----------|--------|-----------|
| AE version | 2024+ | User requirement; modern ExtendScript surface |
| UI | Simple script + alert | Lowest friction; no panel scaffolding |
| Project size | Optimize 100–400 MB | Matches stated workload; scraper bounds already fit |
| Install | Designer one-liner + side-by-side JSX | No admin; works on locked machines |
| Mutation | None | Tier 0 Observer promise |
| Lint | Best-effort after ingest | Ingest summary still valuable if lint fails |

## Upstream pieces reused

- `integrations/after-effects/MographJailed_ProjectScraper.jsx`  
  Read-only, bounds-enforced, CI-guarded against DOM mutation.
- `integrations/after-effects/MographJailed_Client.jsxinc`  
  Protocol v1 client: Base64 args, allowlisted commands, response parse.
- CLI ops: `project.ingest`, `expression.lint`, `system.probe`

Schema: `docs/MJ_PROJECT_SCRAPE_1.md` in the upstream repo.

## Out of scope for this package

- Auto-relink
- Writing back into the `.aep`
- Plugin SHA audit UI (use upstream `plugin.audit` later)
- Watcher / LaunchAgent
- Frame extraction or Core Image
- Any network service

## Future small upgrades (still simple)

- Default receipts folder (skip second dialog)
- Write report `.txt` next to the receipt
- Optional one-click `project.snapshot` after a clean health check

## References

- https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI
- Upstream SECURITY.md, PROTOCOL.md, ARCHITECTURE.md, ROADMAP.md, TIER0_OBSERVER.md
