<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.33.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **reviewdog--action-eslint/v1.33.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh fetches the reviewdog install script from a mutable branch URL (master) on raw.githubusercontent.com and pipes it directly to `sh` without first saving it to a file. This means any compromise of that URL or a MITM attack could execute arbitrary code on the runner. Offending line: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1`

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of workflow-controllable inputs allow shell metacharacter injection:

1. Line 24: `${INPUT_ESLINT_FLAGS:-'.'}` is unquoted inside the double-quoted string passed to `npx --no-install -c "eslint -f=... ${INPUT_ESLINT_FLAGS:-'.'}"`  — an attacker-controlled `eslint_flags` input containing shell metacharacters (`;`, `|`, `$()`, etc.) will be interpreted by the shell before npx sees them.

2. Line 31: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted as a trailing positional argument to `reviewdog`, allowing word-splitting and glob expansion of the `reviewdog_flags` input, which can inject additional flags or shell metacharacters.

Locations:

- `script.sh:24`
- `script.sh:31`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed script.sh:
1. unsafe-shell (line 11): Replaced `curl ... | sh` with download-then-execute pattern: curl saves the install script to a mktemp file, sh executes it, then the temp file is removed.
2. script-injection (line 24): Replaced `npx --no-install -c "eslint -f=... ${INPUT_ESLINT_FLAGS:-'.'}"` with `npx --no-install eslint -f "${ESLINT_FORMATTER}" "${ESLINT_FLAGS}"` where ESLINT_FLAGS is pre-computed with the default applied, and all arguments are properly double-quoted.
3. script-injection (line 31): Changed unquoted `${INPUT_REVIEWDOG_FLAGS}` to `${INPUT_REVIEWDOG_FLAGS:+"${INPUT_REVIEWDOG_FLAGS}"}` so it is double-quoted when non-empty and omitted entirely when empty.

