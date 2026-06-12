<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.33.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **reviewdog--action-eslint/v1.33.2** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remotely fetched install script directly to `sh` without first downloading and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- ...` executes arbitrary remote content in the runner shell. If the remote URL is compromised or the content is tampered with in transit, malicious code will execute directly.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of workflow-controllable inputs in script.sh:

1. Line 25: `${INPUT_ESLINT_FLAGS:-'.'}` is interpolated without its own quoting inside the double-quoted string passed to `npx -c`. INPUT_ESLINT_FLAGS holds `${{ inputs.eslint_flags }}` (set in action.yml env block). An attacker-controlled value containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the eslint argument and inject arbitrary commands.

2. Line 32: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted at the end of the reviewdog invocation. INPUT_REVIEWDOG_FLAGS holds `${{ inputs.reviewdog_flags }}`. An unquoted expansion allows word splitting and glob expansion of attacker-controlled content, enabling argument injection or command injection.

Locations:

- `script.sh:25`
- `script.sh:32`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed script.sh with two changes:
1. unsafe-shell (line 11): Replaced `curl -sfL ... | sh -s` pipe pattern with a safe download-then-execute approach: curl downloads the install script to a temp file, sh executes it, then the temp file is removed.
2. script-injection (lines 25 & 32): (a) INPUT_ESLINT_FLAGS is now stored in ESLINT_FLAGS with a default value using `${INPUT_ESLINT_FLAGS:-.}` and then properly double-quoted inside the npx -c string as `\"${ESLINT_FLAGS}\"`, preventing shell metacharacter injection. (b) INPUT_REVIEWDOG_FLAGS is now passed using `${INPUT_REVIEWDOG_FLAGS:+"${INPUT_REVIEWDOG_FLAGS}"}` which drops the argument when empty and double-quotes it when present, preventing word splitting and glob expansion of attacker-controlled content.

