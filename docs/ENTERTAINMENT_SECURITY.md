# Entertainment-industry security alignment (MPAA / TPN-oriented)

**Not a certification.** This document maps Observer design choices to common
studio and vendor expectations (MPAA content security themes, Trusted Partner
Network-style controls, production cybersecurity hygiene). A formal audit is
always client- and title-specific.

## Goals that match industry posture

| Theme | Industry expectation | MJ Observer posture |
|-------|----------------------|---------------------|
| Least privilege | No admin for daily tools | User-level only; no sudo |
| No silent source mutation | Protect picture/editorial masters | Never write `.aep`/`.c4d` sources; snapshot is additive |
| Local / controlled processing | Limit cloud exfil of unreleased media | No network in `mj-observe` / `mj-snapshot` |
| Auditability | Know what ran and where outputs went | Receipts, HEALTH.txt, unique report names, hand-off packs |
| Path control | Outputs stay in show folders | `--jail` (F1); `shot` jails to shot dir |
| Integrity | Detect unexpected change | Hash snapshots; hash-skip identical bytes |
| Vendor hardening | Avoid supply-chain / PATH tricks | Fail-closed absolute `/bin` `/usr/bin` adapters (F5) |
| Need-to-know | Limit distribution of assets | Pack is explicit; user chooses what to archive |

## MPAA-style content security themes (informal mapping)

Studios often assess:

1. **Physical & facility** — out of scope for this software.  
2. **Digital security** — access control, malware, encryption at rest/in transit, secure deletion.  
3. **Access control** — accounts, least privilege, logging.  
4. **Network** — segmentation, no unauthorized transmit of content.  

Observer contribution:

- Supports **digital** and **access** hygiene on the artist workstation by remaining offline, non-mutating, and path-jailed when `--jail` / `shot` is used.  
- Does **not** replace DLP, disk encryption (FileVault), IdP, or MAM/VPN policy.  
- Hand-off packs can contain project snapshots — treat them as **content** under the same rules as a QuickTime playblast (need-to-know, encrypted transit if they leave the facility).

## Trusted Partner Network (TPN) style notes

TPN assessments emphasize policies, training, and technical controls at the
vendor. For a motion-design vendor using this tool:

| Control idea | How to use MJ |
|--------------|---------------|
| Document approved tools | List `mj-observe` / MographJailed in the tool inventory |
| Prevent unauthorized cloud upload | Tool has no upload path; still ban drag-drop to consumer cloud in policy |
| Protect work-in-progress | Snapshots under show volume; not Desktop/iCloud by policy + `--jail` |
| Logging | Keep `HEALTH-*.txt` and pack `MACHINE.txt` with show archives if required |
| Incident response | Non-mutation reduces “tool wiped the cut” class incidents |

## Operational rules for show use

1. Prefer `/bin/zsh -f tools/mj-observe.zsh …`  
2. Always use `shot` or `--jail /path/to/show/shot` for report/pack.  
3. Do not pass `--out` to home cloud-synced folders unless policy allows.  
4. Treat HTML reports as **internal**; they may list asset names (not always public).  
5. Snapshot and pack increase disk use — budget show storage (F4 tracked).  
6. Upstream AE/`c4dpy` still subject to Adobe/Maxon licensing and studio software policy.

## Finding tracker (F1–F5)

| ID | Status in 0.2.2-dev | Fix |
|----|---------------------|-----|
| **F1** | **Mitigated** | `--jail DIR`; `shot` and default `pack` jail to shot dir |
| **F2** | **Mitigated** | Unique `mj-health-report-TIMESTAMP-PID.html` unless `--force` |
| **F3** | **Mitigated** | Snapshot stamp includes `$$` (pid) |
| **F4** | **Tracked** | Pack prints disk-use warning; no silent delete of stage |
| **F5** | **Mitigated** | Fail-closed absolute adapters; no PATH fallback |

## What this tool is not

- Not an MPAA or TPN certification  
- Not DRM, watermarking, or forensic marking  
- Not a substitute for FileVault, MDM, or SSO  
- Not a render farm or content transfer system  

## See also

- [SECURITY_REDTEAM.md](SECURITY_REDTEAM.md)  
- [ZSH_HARDENING.md](ZSH_HARDENING.md)  
- [STOCK_ZSH_BASELINE.md](STOCK_ZSH_BASELINE.md)  
