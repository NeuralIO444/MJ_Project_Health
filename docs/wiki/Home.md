# MJ Project Health — Wiki

**GitHub:** https://github.com/NeuralIO444/MJ_Project_Health

Offline-first Observer for motion-graphics shots on locked-down Macs.

## Start here

1. [README](../../README.md) — install and quick start  
2. [mj-observe(1)](../man/mj-observe.1.md) — CLI reference  
3. [mj-snapshot(1)](../man/mj-snapshot.1.md) — hash snapshots  
4. [Security red team](../SECURITY_REDTEAM.md) — blast radius  
5. [Entertainment security](../ENTERTAINMENT_SECURITY.md) — MPAA/TPN-oriented map  

## Workflows

| Workflow | Page |
|----------|------|
| AE Project Health script | [ae/README](../../ae/README.md) |
| C4D scene scrape | [integrations/cinema4d](../../integrations/cinema4d/README.md) |
| Dual AE↔C4D | [AE_C4D_INTEGRATION](../AE_C4D_INTEGRATION.md) |
| Stock Sequoia baseline | [STOCK_ZSH_BASELINE](../STOCK_ZSH_BASELINE.md) |
| Response field map | [RESPONSE_SHAPES](../RESPONSE_SHAPES.md) |
| C4D schema | [MJ_C4D_SCRAPE_1](../MJ_C4D_SCRAPE_1.md) |
| Test / regression | [TEST_CHECKLIST](../TEST_CHECKLIST.md) |

## Security checklist (artist)

- [ ] Run with `/bin/zsh -f`  
- [ ] Use `--jail` or `shot` so outputs stay on the show volume  
- [ ] Do not `--out` to consumer cloud folders unless policy allows  
- [ ] Treat HTML reports and hand-off packs as WIP content  

## Version

CLI **0.2.2-dev** — jail, fail-closed adapters, CSP dashboard, unique report names.
