# Test checklist — MJ Project Health

Run on a limited macOS with AE 2024+ and MographJailed installed via the designer path.

## Setup verification

- [ ] `~/Documents/MographJailed/dist/mograph-jailed.zsh` exists
- [ ] `MographJailed_ProjectScraper.jsx` and `MographJailed_Client.jsxinc` sit next to `MJ_Project_Health.jsx`
- [ ] `CLI_PATH` inside the health script matches the real runtime path

## Functional cases

| # | Scenario | Expected |
|---|----------|----------|
| 1 | No project open | Alert: “No project is open.” |
| 2 | Clean project, no missing footage, no bad expressions | Status **PASS** |
| 3 | Intentionally missing footage item | Status **BLOCKERS**, Missing > 0 |
| 4 | Expression with broken layer / effect reference | Status **WARNINGS** (or BLOCKERS if also missing footage); finding listed under lint |
| 5 | Wrong `CLI_PATH` | Clear “runtime not found” message with path shown |
| 6 | Scraper JSX missing from folder | Clear “Scraper not found” message |
| 7 | User cancels receipts-folder dialog | Script exits quietly |
| 8 | User cancels receipt-file dialog | Script exits quietly |
| 9 | Receipt from a different project | Ingest still validates; numbers match that receipt |
| 10 | Very large project that hits scraper caps | Report notes truncation; no crash |

## Safety checks

- [ ] After a full run, the open `.aep` is unmodified (no dirty flag from the script)
- [ ] No source media files changed (size/mtime)
- [ ] Only new files: the `.scrape.json` in the user-chosen folder (and transient request files that are deleted)
- [ ] Probe / ingest / lint failures surface structured error codes when the CLI returns them

## Performance (100–400 MB projects)

- [ ] Typical project completes in a tolerable interactive window (scraper is the main cost)
- [ ] Alert appears; AE remains responsive after the script finishes

## Notes

Record AE version, macOS version, and approximate `.aep` size for any failure.  
If `ingest.data` field names differ from the script’s expectations on a newer CLI, capture the raw JSON envelope and adjust the report section.
