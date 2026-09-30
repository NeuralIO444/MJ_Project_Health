# MJ Project Health

**Tier 0 Observer tool for After Effects 2024+ on limited / locked-down macOS.**

One simple script that answers:

> Is this project safe to work on, hand off, or render?

Read-only. Zero install beyond MographJailed. No sudo, no Homebrew, no Python/Node/FFmpeg. Source media and the `.aep` are never modified.

---

## What it does

1. Runs the official **MographJailed Project Scraper** (read-only ES3 traversal of the open project).
2. Calls `project.ingest` to validate the scrape receipt and summarize comps / layers / expressions / fonts / footage / missing items.
3. Calls `expression.lint` for static analysis of scraped expressions (broken refs, dangerous patterns, etc.).
4. Shows a plain-text health report in an alert.

**Status levels**

| Status    | Meaning                                      |
|-----------|----------------------------------------------|
| PASS      | No missing footage, no lint findings         |
| WARNINGS  | Expression issues found                      |
| BLOCKERS  | Missing / unlinked footage                   |

Optimized for typical **100–400 MB** `.aep` projects (scraper bounds already fit this range).

---

## Requirements

- macOS with stock `/bin/zsh` (no admin rights needed)
- After Effects **2024 or newer**
- [MographJailed](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI) installed via the designer one-liner

---

## Install

### 1. Install MographJailed (once)

```sh
curl -fsSL https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/tools/install-designer.zsh | zsh
```

Default location: `~/Documents/MographJailed`  
Runtime: `~/Documents/MographJailed/dist/mograph-jailed.zsh`

### 2. Get the AE scripts

Place these three files in the **same folder** (recommended: `~/Documents/MographJailed/ae/`):

| File | Source |
|------|--------|
| `MographJailed_ProjectScraper.jsx` | [upstream](https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/integrations/after-effects/MographJailed_ProjectScraper.jsx) |
| `MographJailed_Client.jsxinc` | [upstream](https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/integrations/after-effects/MographJailed_Client.jsxinc) |
| `MJ_Project_Health.jsx` | this repo (`ae/MJ_Project_Health.jsx`) |

Quick fetch of the two upstream files:

```sh
mkdir -p ~/Documents/MographJailed/ae
cd ~/Documents/MographJailed/ae
curl -fsSL -O https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/integrations/after-effects/MographJailed_ProjectScraper.jsx
curl -fsSL -O https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/integrations/after-effects/MographJailed_Client.jsxinc
# then copy MJ_Project_Health.jsx into the same folder
```

If your MographJailed install path differs, edit `CLI_PATH` at the top of `MJ_Project_Health.jsx`.

---

## Usage

1. Open a project in After Effects 2024+.
2. **File → Scripts → Run Script File…**
3. Choose `MJ_Project_Health.jsx`.
4. When the scraper prompts, pick a receipts folder (e.g. `~/Documents/AE_Receipts`).
5. When asked, select the `.scrape.json` that was just written.
6. Read the health report.

Typical runtime on a 100–400 MB project: a few seconds to ~30 s (scraper dominates).

---

## Safety guarantees

- Scraper is strictly read-only (CI guard in upstream rejects any AE DOM mutation).
- Only writes: the user-chosen scrape JSON + temporary protocol request files (deleted immediately).
- No source media mutation.
- No project save / close / undo group.
- Network / unknown volumes fail closed inside MographJailed Standard Library.
- Protocol v1 allowlisted commands only (`project.ingest`, `expression.lint`).

See upstream [SECURITY.md](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI/blob/main/SECURITY.md) and [TIER0_OBSERVER.md](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI/blob/main/docs/TIER0_OBSERVER.md).

---

## Project size notes (100–400 MB)

Upstream scraper bounds (already appropriate):

- Max 200 comps
- Max 500 layers per comp
- Max 2000 footage items
- Expressions truncated at 2000 characters
- Total JSON kept under ~5 MB

If a project hits a cap you will see `compsTruncated` / `footageTruncated` in the report. Do not raise the limits for normal work in this size range.

---

## Ranked roadmap (highest return first)

Derived from the design discussion for limited-macOS AE expansion:

| Rank | Tool | Return | Status |
|------|------|--------|--------|
| 1 | **Project Health / Observer** | Highest — missing footage + expression bugs before render/hand-off | **This package** |
| 2 | Expression Linter (standalone depth) | High — catches render-time only failures | Included via `expression.lint` |
| 3 | Non-destructive Auto-Snapshot | High — version chaos prevention | Upstream `project.snapshot` + optional watcher |
| 4 | Missing footage / font / plugin audit pack | High | Partial (footage + fonts here; plugin.audit upstream) |
| 5 | Asset Manifest + Verify | Medium-High | Upstream 0.2 line |
| 6 | Storage Preflight | Medium | Upstream |
| 7+ | Media timing, frame extract, image compare, NativeDB indexes | Later | Gated / roadmap |

---

## Related upstream docs

- [MographJailed README](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI)
- [PROTOCOL.md](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI/blob/main/PROTOCOL.md)
- [MJ_PROJECT_SCRAPE_1 schema](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI/blob/main/docs/MJ_PROJECT_SCRAPE_1.md)
- [ARCHITECTURE.md](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI/blob/main/ARCHITECTURE.md)
- [ROADMAP.md](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI/blob/main/ROADMAP.md)

---

## License

MIT (aligned with upstream MographJailed).  
The Project Health script is a thin consumer of the upstream protocol and scraper; keep upstream files in sync when upgrading MographJailed.
