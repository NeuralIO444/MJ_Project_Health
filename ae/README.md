# AE scripts

| File | Role |
|------|------|
| `MJ_Project_Health.jsx` | Main entry — run this from After Effects |
| `MographJailed_ProjectScraper.jsx` | **Fetch from upstream** (not vendored here) |
| `MographJailed_Client.jsxinc` | **Fetch from upstream** (not vendored here) |

## Fetch upstream companions

```sh
cd "$(dirname "$0")"
curl -fsSL -O https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/integrations/after-effects/MographJailed_ProjectScraper.jsx
curl -fsSL -O https://raw.githubusercontent.com/NeuralIO444/Mograph_Jailed_OSX_CLI/main/integrations/after-effects/MographJailed_Client.jsxinc
```

Keep these three files in the same folder. Edit `CLI_PATH` inside `MJ_Project_Health.jsx` if MographJailed is not at `~/Documents/MographJailed`.
