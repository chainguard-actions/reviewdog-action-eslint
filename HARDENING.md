<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.33.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.33.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- ...` executes arbitrary remote content in the runner shell. If the remote URL is compromised or the connection is intercepted, malicious code runs immediately with no integrity check.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of untrusted input-derived env vars in script.sh.

(1) Line 26: `${INPUT_ESLINT_FLAGS:-'.'}` is unquoted inside the double-quoted string passed to `npx --no-install -c "eslint -f=..."`. INPUT_ESLINT_FLAGS is set from `inputs.eslint_flags` (an attacker-controlled value). Shell metacharacters (`;`, `|`, `$(...)`, etc.) in the value will be interpreted by the shell, enabling command injection.

(2) Line 34: `${INPUT_REVIEWDOG_FLAGS}` is completely unquoted at the end of the reviewdog invocation. INPUT_REVIEWDOG_FLAGS is set from `inputs.reviewdog_flags`. Without quoting, word splitting and glob expansion apply, and shell metacharacters in the value allow arbitrary command injection.

Locations:

- `script.sh:26`
- `script.sh:34`

### unpinned-uses (severity: high)

All `uses:` references across all workflow files use mutable version tags instead of immutable 40-character SHA commit hashes. If any referenced action's tag is moved (intentionally or via a supply-chain attack), the workflow will silently execute different code. Failing references include:
- `actions/checkout@v4` (depup.yml, npm-publish.yml, release.yml, reviewdog.yml, test.yml)
- `haya14busa/action-depup@v1` (depup.yml)
- `peter-evans/create-pull-request@v6` (depup.yml)
- `actions/setup-node@v4` (npm-publish.yml, reviewdog.yml, test.yml)
- `JS-DevTools/npm-publish@v3` (npm-publish.yml)
- `haya14busa/action-bumpr@v1` (release.yml x2)
- `haya14busa/action-update-semver@v1` (release.yml)
- `haya14busa/action-cond@v1` (release.yml)

Locations:

- `.github/workflows/depup.yml:11`
- `.github/workflows/npm-publish.yml:9`
- `.github/workflows/release.yml:16`
- `.github/workflows/reviewdog.yml:16`
- `.github/workflows/test.yml:8`

### missing-permissions (severity: medium)

None of the five workflow files define a top-level `permissions:` key, and no individual job defines its own `permissions:` block. Without explicit permissions, workflows run with the repository's default token permissions (which may be `write-all` on older repositories or permissive org defaults), granting broader access than necessary. Affected files: depup.yml, npm-publish.yml, release.yml, reviewdog.yml, test.yml.

Locations:

- `.github/workflows/depup.yml:1`
- `.github/workflows/npm-publish.yml:1`
- `.github/workflows/release.yml:1`
- `.github/workflows/reviewdog.yml:1`
- `.github/workflows/test.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all four findings:

1. unsafe-shell (script.sh): Replaced `curl ... | sh` pipe with a two-step approach: download install script to a temp file with `curl -sfL -o`, execute it separately with `sh`, then clean up.

2. script-injection (script.sh): (a) Moved INPUT_ESLINT_FLAGS into a variable ESLINT_FLAGS and quoted it with escaped double-quotes inside the npx -c string. (b) Added double-quotes around INPUT_REVIEWDOG_FLAGS to prevent word splitting and glob expansion.

3. unpinned-uses: Pinned all 8 distinct action references across 5 workflow files to full 40-character SHA hashes with original tags preserved as comments: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5, actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020, haya14busa/action-depup@99f7aecf3e4d06d5a3faf190dae5dc79ac530b5a, peter-evans/create-pull-request@c5a7806660adbe173f04e3e038b0ccdcd758773c, JS-DevTools/npm-publish@19c28f1ef146469e409470805ea4279d47c3d35c, haya14busa/action-bumpr@faf6f474bcb6174125cfc569f0b2e24cbf03d496, haya14busa/action-update-semver@7d2c558640ea49e798d46539536190aff8c18715, haya14busa/action-cond@94f77f7a80cd666cb3155084e428254fea4281fd.

4. missing-permissions: Added minimal top-level permissions blocks to all 5 workflow files (depup.yml: contents:read + pull-requests:write; npm-publish.yml: contents:read; release.yml: contents:write + pull-requests:write; reviewdog.yml: contents:read + pull-requests:write + checks:write; test.yml: contents:read).

