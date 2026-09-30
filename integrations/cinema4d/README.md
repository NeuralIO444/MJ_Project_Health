# Cinema 4D integration (Observer)

| Piece | Status |
|-------|--------|
| Schema | [docs/MJ_C4D_SCRAPE_1.md](../../docs/MJ_C4D_SCRAPE_1.md) |
| Scraper | `scene_health.py` — run under **c4dpy** only |
| Fixture | [docs/fixtures/sample-c4d.MJ_C4D_SCRAPE_1.json](../../docs/fixtures/sample-c4d.MJ_C4D_SCRAPE_1.json) |
| Native `c4d.ingest` | Upstream Protocol territory (optional) |
| Consumer | `mj-observe` aggregates receipts; HTML dashboard AE-first for now |

## Requirements (target Mac)

- Maxon Cinema 4D installed
- Valid license for headless `c4dpy`
- Typical binary:

```text
/Applications/Maxon Cinema 4D <version>/c4dpy.app/Contents/MacOS/c4dpy
```

## Scrape (read-only)

```zsh
C4DPY="/Applications/Maxon Cinema 4D 2025/c4dpy.app/Contents/MacOS/c4dpy"
"$C4DPY" /path/to/this/repo/integrations/cinema4d/scene_health.py \
  /absolute/path/to/shot.c4d \
  /absolute/path/to/shot/mj-receipts
```

Writes `shot.MJ_C4D_SCRAPE_1.json`. Does not save the project.

## Safety

- Read-only Observer only  
- `allowDialogs=False` on asset enumeration  
- Fail closed if not running under c4dpy  
- Never overwrite source `.c4d` or textures  

Product integration (Cineware, multipass) remains Adobe/Maxon — see `docs/AE_C4D_INTEGRATION.md`.
