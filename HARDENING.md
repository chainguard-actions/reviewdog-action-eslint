<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.34.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.34.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. Although the URL is pinned to a specific commit SHA, the content is still executed immediately without inspection, which is an unsafe shell pattern.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of untrusted inputs in script.sh:

1. Line 24: `${INPUT_ESLINT_FLAGS:-'.'}` is unquoted inside the double-quoted string passed to `npx --no-install -c "eslint -f=..."`. Since INPUT_ESLINT_FLAGS is set from `inputs.eslint_flags` (a caller-controlled value), shell metacharacters in the value can break out of the intended command context.

2. Line 31: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted as a trailing argument to the reviewdog command. INPUT_REVIEWDOG_FLAGS is set from `inputs.reviewdog_flags` (caller-controlled), so an attacker can inject arbitrary shell words, flags, or metacharacters via word-splitting and glob expansion.

Locations:

- `script.sh:24`
- `script.sh:31`

### missing-permissions (severity: medium)

None of the workflow files define a `permissions:` key at the top level or at the job level. Without explicit permissions, workflows run with the default token permissions (which may be read/write depending on repository settings), violating the principle of least privilege. Affected files: depup.yml, npm-publish.yml, release.yml, reviewdog.yml, test.yml.

Locations:

- `.github/workflows/depup.yml:1`
- `.github/workflows/npm-publish.yml:1`
- `.github/workflows/release.yml:1`
- `.github/workflows/reviewdog.yml:1`
- `.github/workflows/test.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, missing-permissions

**Notes:**

1. unsafe-shell (script.sh line 11): Replaced `curl | sh` pipe with a two-step approach: download install script to a temp file, execute it separately, then clean up. 2. script-injection (script.sh lines 24 & 31): Stored INPUT_ESLINT_FLAGS in a quoted variable; split INPUT_REVIEWDOG_FLAGS into a bash array using `read -ra` and expanded with `"${reviewdog_flags[@]}"`. Updated shebang from #!/bin/sh to #!/bin/bash to support arrays (script was already run with bash per action.yml). 3. missing-permissions: Added minimal permissions blocks to all 5 workflow files: depup.yml (contents:write, pull-requests:write), npm-publish.yml (contents:read), release.yml (contents:write), reviewdog.yml (contents:read, pull-requests:write, checks:write), test.yml (contents:read).

