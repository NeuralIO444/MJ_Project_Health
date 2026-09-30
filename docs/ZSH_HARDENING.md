# Zsh hardening (Observer tools)

## Run clean

```zsh
/bin/zsh -f tools/mj-observe.zsh help
/bin/zsh -f tools/mj-snapshot.zsh --help
```

`-f` skips user `.zshrc` so aliases and PATH hacks cannot alter behavior.

## Options

| Option | Why |
|--------|-----|
| `emulate -L zsh` | Local option scope |
| `err_return` | Fail on command errors |
| `extended_glob` / `null_glob` | Safe globs |
| `warn_create_global` | Catch accidental globals |
| `unsetopt nounset` | Optional CLI flags may be empty |

## Fixed adapters

Prefer absolute stock paths: `/bin/cp`, `/bin/mkdir`, `/usr/bin/shasum`, `/usr/bin/python3`, `/usr/bin/tar`, `/usr/bin/grep`, `/usr/bin/sw_vers`.

Fall back to bare names only if the absolute binary is missing (unusual on Sequoia).

## Errors

Hard failures print to **stderr** (`print -u2`). Status lines and reports stay on stdout for piping.

## Not used

- `eval` of user input
- `PATH` mutation
- `no_unset` forced on (breaks optional flags)
- GNU-only flags on BSD `cp`/`mkdir` (`--` long options)

## Syntax check (dev Mac)

```zsh
/bin/zsh -n tools/mj-observe.zsh
/bin/zsh -n tools/mj-snapshot.zsh
```
