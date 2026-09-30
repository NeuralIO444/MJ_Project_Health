# MJ Project Health

**Tier 0 Observer for After Effects + Cinema 4D on limited macOS Sequoia.**

Answers:

> Is this shot safe to work on, hand off, or render?

Read-only. Stock `/bin/zsh`. No sudo, no Homebrew required at runtime. Source `.aep` / `.c4d` are never modified.

**Repo:** https://github.com/NeuralIO444/MJ_Project_Health  
**Upstream protocol:** [MographJailed](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI)  
**CLI version:** 0.2.2-dev

---

## Status levels

| Status | Meaning |
|--------|---------|
| **PASS** | No missing AE footage / C4D assets; no lint errors |
| **WARNINGS** | Lint warnings and/or unlinked AE footage |
| **BLOCKERS** | Missing assets/footage and/or lint errors |

---

## Quick start

```zsh
git clone https://github.com/NeuralIO444/MJ_Project_Health.git
cd MJ_Project_Health
chmod +x tools/mj-observe.zsh tools/mj-snapshot.zsh

# Prefer a clean shell (no user rc)
/bin/zsh -f tools/mj-observe.zsh help
/bin/zsh -f tools/mj-observe.zsh describe

# Offline HTML dashboard from fixtures (AE + C4D)
/bin/zsh -f tools/mj-observe.zsh report \
  --ingest docs/fixtures/sample-ingest.MJ_PROJECT_SUMMARY_1.json \
  --lint   docs/fixtures/sample-lint.MJ_EXPRESSION_LINT_1.json \
  --c4d    docs/fixtures/sample-c4d.MJ_C4D_SCRAPE_1.json \
  --out    /tmp/mj-out \
  --jail   /tmp/mj-out
open /tmp/mj-out/mj-health-report*.html
```

### After Effects (host scrape)

1. Install [MographJailed](https://github.com/NeuralIO444/Mograph_Jailed_OSX_CLI).  
2. Place `ae/MJ_Project_Health.jsx` next to upstream `MographJailed_ProjectScraper.jsx` + `MographJailed_Client.jsxinc`.  
3. AE 2024+ → **File > Scripts > Run Script File…**

### Cinema 4D (host scrape)

```zsh
c4dpy integrations/cinema4d/scene_health.py /abs/shot.c4d /abs/shot/mj-receipts
```

### Shot orchestration

```zsh
/bin/zsh -f tools/mj-observe.zsh shot /Shows/Title/SH010
# discovers .aep/.c4d, describes machine, reports from mj-receipts/ (jailed under shot)
```

### Snapshot (non-overwrite)

```zsh
/bin/zsh -f tools/mj-snapshot.zsh /Shows/Title/SH010/SH010.aep
/bin/zsh -f tools/mj-observe.zsh snapshot /Shows/Title/SH010/SH010.c4d --out /Shows/Title/SH010/mj-versions
```

---

## Security (studio-oriented)

| Control | Implementation |
|---------|----------------|
| No source mutation | Snapshot copies only; refuse existing dest |
| No network in CLI | No curl/wget; HTML CSP `connect-src 'none'` |
| Path jail | `--jail DIR`; `shot` / default `pack` jail to shot dir |
| Fail-closed adapters | Absolute `/bin` + `/usr/bin` only |
| Non-clobber reports | Unique `mj-health-report-TIMESTAMP-PID.html` unless `--force` |
| Red-team notes | [docs/SECURITY_REDTEAM.md](docs/SECURITY_REDTEAM.md) |
| MPAA/TPN-style map | [docs/ENTERTAINMENT_SECURITY.md](docs/ENTERTAINMENT_SECURITY.md) |

```zsh
# Report must stay under show volume
mj-observe report --ingest sum.json --out /Shows/X/SH010/out --jail /Shows/X/SH010
```

---

## Documentation map

| Doc | Topic |
|------|--------|
| [docs/man/mj-observe.1.md](docs/man/mj-observe.1.md) | Full CLI manual |
| [docs/man/mj-snapshot.1.md](docs/man/mj-snapshot.1.md) | Snapshot manual |
| [docs/wiki/Home.md](docs/wiki/Home.md) | Wiki-style index |
| [docs/RESPONSE_SHAPES.md](docs/RESPONSE_SHAPES.md) | AE ingest/lint fields |
| [docs/MJ_C4D_SCRAPE_1.md](docs/MJ_C4D_SCRAPE_1.md) | C4D scrape schema |
| [docs/STOCK_ZSH_BASELINE.md](docs/STOCK_ZSH_BASELINE.md) | Ship stock Sequoia |
| [docs/ZSH_HARDENING.md](docs/ZSH_HARDENING.md) | Shell hardening |
| [docs/AE_C4D_INTEGRATION.md](docs/AE_C4D_INTEGRATION.md) | Cineware / dual-host |
| [docs/TEST_CHECKLIST.md](docs/TEST_CHECKLIST.md) | QA + security greps |

---

## Layout

```text
ae/                    MJ_Project_Health.jsx
tools/                 mj-observe.zsh  mj-snapshot.zsh
web/                   dashboard_template.html (CSP)
integrations/cinema4d/ scene_health.py (c4dpy)
docs/                  design, security, man, wiki, fixtures
```

---

## Requirements

- macOS (Sequoia baseline) with stock `/bin/zsh`
- Optional: AE 2024+ and MographJailed for AE host path  
- Optional: Cinema 4D + `c4dpy` for C4D host path  
- `/usr/bin/python3` for HTML report injection  

---

## License

MIT — see [LICENSE](LICENSE).
