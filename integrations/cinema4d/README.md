# Cinema 4D integration (Observer)

Skeleton for the C4D host side of MographJailed-style dual-host health.

| Piece | Status |
|-------|--------|
| Schema draft | See [docs/AE_C4D_INTEGRATION.md](../../docs/AE_C4D_INTEGRATION.md) §9 |
| `c4dpy` scraper | Planned — `scene_health.py` (not shipped yet) |
| Native `c4d.ingest` | Upstream Protocol territory |
| Consumer report | Parallel to `ae/MJ_Project_Health.jsx` |

## Requirements (target Mac)

- Maxon Cinema 4D installed (full app; Lite alone is insufficient for full `c4dpy` production use)
- Valid license for headless `c4dpy`
- Typical binary path:

```text
/Applications/Maxon Cinema 4D <version>/c4dpy.app/Contents/MacOS/c4dpy
```

## Intended scrape flow

```text
c4dpy scene_health.py /absolute/path/to/shot.c4d
  → writes MJ_C4D_SCRAPE_1.json (user-chosen or default receipts dir)
  → no project save, no asset mutation
```

## Safety

- Read-only Observer only  
- `allowDialogs=False` on asset enumeration  
- Fail closed if `c4dpy` missing or license blocks headless run  
- Never overwrite source `.c4d` or textures  

Full product integration (Cineware, multipass, Live Link) remains Adobe/Maxon — see AE_C4D_INTEGRATION.md.
