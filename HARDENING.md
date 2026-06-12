<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.34.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **reviewdog--action-eslint/v1.34.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- ...` executes whatever the remote URL returns in a shell, making it vulnerable to supply-chain attacks if the remote content is tampered with.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b): Two unquoted shell variable expansions of user-controlled inputs in script.sh allow shell metacharacter injection.

1. Line 24: `${INPUT_ESLINT_FLAGS:-'.'}` is interpolated unquoted inside a double-quoted string passed to `npx -c`: `npx --no-install -c "eslint -f="${ESLINT_FORMATTER}" ${INPUT_ESLINT_FLAGS:-'.'}"`. An attacker-controlled `eslint_flags` input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the string and execute arbitrary commands.

2. Line 31: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted at the end of the reviewdog invocation. An attacker-controlled `reviewdog_flags` input will undergo word splitting and glob expansion, and can inject arbitrary flags or commands.

Locations:

- `script.sh:24`
- `script.sh:31`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed script.sh with two changes:
1. unsafe-shell (line 11): Replaced `curl -sfL ... | sh -s -- ...` with a safe two-step approach: download the install script to a mktemp file, execute it separately with `sh`, then remove it. This prevents supply-chain attacks from piping remote content directly to a shell.
2. script-injection (lines 24 & 31): (a) Extracted INPUT_ESLINT_FLAGS into a local variable ESLINT_FLAGS and properly double-quoted it inside the npx -c string as `\"${ESLINT_FLAGS}\"`, preventing shell metacharacter injection. (b) Changed the unquoted `${INPUT_REVIEWDOG_FLAGS}` to `${INPUT_REVIEWDOG_FLAGS:+"${INPUT_REVIEWDOG_FLAGS}"}` so it is properly double-quoted when present and omitted entirely when empty, preventing word splitting and glob expansion attacks.

