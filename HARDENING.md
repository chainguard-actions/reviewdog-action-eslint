<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.33.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.33.2** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. Although the URL is pinned to a specific commit SHA, piping remote content directly to a shell interpreter is a dangerous pattern that bypasses any opportunity to inspect or verify the script before execution.

Locations:

- `script.sh:10`

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansions of user-controlled inputs in script.sh. (1) Line 22: `${INPUT_ESLINT_FLAGS:-'.'}` is unquoted inside the string passed to `npx -c`, allowing shell metacharacters from the `inputs.eslint_flags` value to be interpreted by the shell. (2) Line 29: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted at the end of the reviewdog invocation, allowing shell metacharacters from `inputs.reviewdog_flags` to be interpreted. Both env vars are set directly from `inputs.*` in action.yml and must be double-quoted (e.g. `"${INPUT_ESLINT_FLAGS:-.}"` and `"${INPUT_REVIEWDOG_FLAGS}"`) to prevent command injection.

Locations:

- `script.sh:22`
- `script.sh:29`

### missing-permissions (severity: medium)

None of the workflow files define a top-level `permissions:` block, and no job in any workflow defines a job-level `permissions:` block. Without explicit permissions, workflows run with the default (potentially broad) token permissions. All five workflow files are affected: depup.yml, npm-publish.yml, release.yml, reviewdog.yml, and test.yml.

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

Fixed script.sh: (1) unsafe-shell - replaced `curl ... | sh` with download-then-execute pattern: curl downloads to a temp file, sh executes it, then it's removed; (2) script-injection - double-quoted ${INPUT_ESLINT_FLAGS:-.} inside the npx -c string and ${INPUT_REVIEWDOG_FLAGS} as the final reviewdog argument. Added minimal permissions blocks to all 5 workflow files: depup.yml (contents:write, pull-requests:write), npm-publish.yml (contents:read), release.yml (contents:write, pull-requests:write), reviewdog.yml (contents:read, pull-requests:write, checks:write), test.yml (contents:read).

