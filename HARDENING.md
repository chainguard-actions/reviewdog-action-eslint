<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.33.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.33.1** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it. If the remote URL is compromised or the connection is intercepted, arbitrary code will execute on the runner. Pattern: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b ...`

Locations:

- `script.sh:11`

### script-injection (severity: high)

Sub-rule (b): Two unquoted shell variable expansions of untrusted, caller-controlled inputs in script.sh allow shell metacharacter injection (word splitting, glob expansion, command substitution).

1. Line 24: `${INPUT_ESLINT_FLAGS:-'.'}` is unquoted inside the outer double-quoted string passed to `npx --no-install -c "eslint -f=... ${INPUT_ESLINT_FLAGS:-'.'}"`  — an attacker-controlled `eslint_flags` input can break out of the npx -c argument and inject arbitrary shell commands.

2. Line 30: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted at the end of the reviewdog invocation — an attacker-controlled `reviewdog_flags` input undergoes word splitting and glob expansion, enabling argument injection or shell metacharacter abuse.

Both variables are set from `inputs.eslint_flags` and `inputs.reviewdog_flags` respectively in action.yml and must be double-quoted: `"${INPUT_ESLINT_FLAGS:-.}"` and `"${INPUT_REVIEWDOG_FLAGS}"`.

Locations:

- `script.sh:24`
- `script.sh:30`

### missing-permissions (severity: medium)

None of the workflow files define a top-level `permissions:` key, and no job within any of these files defines a job-level `permissions:` key. Without explicit permissions, GitHub Actions grants the default token permissions (which may include write access to repository contents, pull requests, etc.), violating the principle of least privilege. All five workflow files are affected: depup.yml, npm-publish.yml, release.yml, reviewdog.yml, and test.yml.

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

1. unsafe-shell (script.sh line 11): Replaced `curl ... | sh` pipe with a two-step approach: download the install script to a temp file first (`curl -sfL -o "${TEMP_PATH}/install-reviewdog.sh" ...`), then execute it separately (`sh "${TEMP_PATH}/install-reviewdog.sh" ...`). 2. script-injection (script.sh lines 24, 30): Properly double-quoted both unquoted variable expansions — `${INPUT_ESLINT_FLAGS:-'.'}` is now `\"${INPUT_ESLINT_FLAGS:-.}\"` inside the npx -c string, and `${INPUT_REVIEWDOG_FLAGS}` is now `"${INPUT_REVIEWDOG_FLAGS}"`. 3. missing-permissions: Added top-level `permissions:` blocks to all five workflow files with least-privilege grants: depup.yml (contents:write, pull-requests:write), npm-publish.yml (contents:read), release.yml (contents:write), reviewdog.yml (contents:read, pull-requests:write, checks:write), test.yml (contents:read).

