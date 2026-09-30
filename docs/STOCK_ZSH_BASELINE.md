# Stock zsh baseline — build high, ship low

**Date:** 2026-09-29  
**Status:** Approved design rule for MJ Project Health and dual-host (AE + C4D) Observer work.

Higher-level tools are fine for **development and QA**.  
**Production runtime** on limited macOS Sequoia is **stock only** — primarily `/bin/zsh` plus fixed `/usr/bin` adapters, plus host apps already on the box (After Effects JSX, Cinema 4D `c4dpy`).

---

## 1. The split

| Phase | Allowed | Purpose |
|-------|---------|---------|
| **Development / QA** | Python, Node, Ruby, extra CLIs, Homebrew *on the build machine*, notebooks, fixture generators | Prototype, test, generate samples, CI |
| **Production runtime** | Stock Sequoia: `/bin/zsh`, `/usr/bin/*` (`sips`, `avmediainfo`, `plutil`, `jq`, `shasum`, `stat`, `df`, …), optional **AE JSX**, optional **`c4dpy`** | What locked-down artist Macs actually run |

MographJailed’s own model: richer modular source + QA → one deterministic dist runner that assumes **stock macOS only**.

---

## 2. Port-down flow

```text
Prototype (dev Mac)
  convenient languages / tools
        ↓  freeze contracts (schemas, status rules, allowlist)
Versioned receipts + Protocol v1 ops
        ↓  reimplement behind the jail
Stock adapters (zsh + fixed /usr/bin paths)
        ↓
Ship: zero Homebrew, zero pip, zero Node on the artist machine
```

### Examples

| Concern | Dev / QA | Sequoia production |
|---------|----------|-------------------|
| Parse scrape JSON | Python / `jq` freely | Stock `/usr/bin/python3` (as upstream Tier 0) and/or pure zsh + `jq` |
| Image probe | Pillow, ImageMagick | **`sips` only** |
| Media timing | ffprobe | **`avmediainfo` only** |
| C4D asset list | Explore API in any Python | **`c4dpy` → JSON receipt** (Maxon runtime, not system pip) |
| AE project walk | Experiments | **Official JSX scraper** → receipt → protocol |
| Reports | Notebooks, rich HTML | Alert + text/JSON envelope |

---

## 3. Host runtimes (allowed “high level” forever)

These are **not** ported down to stock shell — they are the application surfaces:

| Host | Runtime | Role |
|------|---------|------|
| After Effects | ExtendScript / JSX | Project scrape, optional consumer UI |
| Cinema 4D | `c4dpy` | Scene scrape, asset enumeration |

The jail only consumes their **receipts** and runs **stock** checks (existence, hash, `sips`, storage, summaries).

---

## 4. Production must never require

- Homebrew / MacPorts formulas  
- `npm` or global Node  
- User `pip install` / venv as a runtime dependency  
- FFmpeg or ImageMagick as required adapters  
- Protocol commands that mean “run arbitrary Python/shell”

If a feature needs those, it is out of Observer scope or an explicit Tier‑1 optional path, clearly labeled and never the default.

---

## 5. Stock Sequoia toolkit (runtime allowlist target)

| Category | Tools |
|----------|--------|
| Shell | `/bin/zsh` (`-f` safe style preferred for runners) |
| Text | `awk`, `sed`, `grep`, `cut`, `sort`, `uniq`, `wc`, `head`, `tail` |
| Files | `stat`, `file`, `find`, `cp`, `mv`, `mkdir`, `mktemp`, `ditto`, `shasum` |
| Images | `sips` |
| Media | `avmediainfo`, `avconvert`, `afinfo`, `afconvert` |
| Data | `plutil`, `sqlite3`, `jq` (Sequoia+), stock `/usr/bin/python3` where already used upstream |
| System | `sw_vers`, `uname`, `df`, `system_profiler` (read-only inventory) |

Prefer absolute paths to system binaries in shipped scripts. Do not assume GNU coreutils.

---

## 6. Workflow for this package

1. **Spec** — schemas and status rules in `docs/` (done for AE shapes; C4D draft in AE_C4D_INTEGRATION).  
2. **Prototype** — any convenient stack on a full Mac.  
3. **Freeze** — field names, severity rules, truncation bounds.  
4. **Port** — allowlisted native ops and/or thin **stock zsh** (+ `jq` where present) consumers.  
5. **Qualify** — limited Sequoia machine with only AE and/or C4D installed; no Homebrew.

---

## 7. One-line rule

**Build with whatever is fast. Ship stock zsh (+ host apps). Port down before release.**

---

*Approved in design chat 2026-09-29. Aligns with MographJailed Tier 0 and limited-macOS constraints.*
