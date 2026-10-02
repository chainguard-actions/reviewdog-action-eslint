<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.36.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.36.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remotely fetched install script directly to `sh` without first downloading it to a file. Even though the URL contains a pinned commit SHA in the path, the content is still executed without any integrity verification step. Pattern: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b ...`

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansion of untrusted data. (1) Line 57: `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"` — the env var INPUT_ESLINT_FLAGS (sourced from `${{ inputs.eslint_flags }}`) is expanded unquoted inside a double-quoted string passed to `eval`, allowing an attacker-controlled value to inject arbitrary shell commands via metacharacters (e.g. `); malicious_cmd; (`). (2) Line 68: `${INPUT_REVIEWDOG_FLAGS}` is passed unquoted as a shell argument (sourced from `${{ inputs.reviewdog_flags }}`), allowing word splitting and shell metacharacter injection.

Locations:

- `script.sh:57`
- `script.sh:68`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed three issues in script.sh: (1) unsafe-shell: replaced 'curl ... | sh -s -- -b ...' with download-to-file then execute pattern (dropped '--' as it was the shell's option terminator, not the script's argument); (2) script-injection at line 57: replaced eval with unquoted INPUT_ESLINT_FLAGS with xargs-based tokenization into ESLINT_FLAGS_ARRAY using 'printf %s | xargs printf %s\0' with a while/read loop; (3) script-injection at line 68: replaced unquoted ${INPUT_REVIEWDOG_FLAGS} with xargs-based tokenization into REVIEWDOG_FLAGS_ARRAY with a proper if [ -n ... ] guard to prevent GNU xargs empty-input issue.

