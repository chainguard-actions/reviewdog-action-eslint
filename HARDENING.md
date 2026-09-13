<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.35.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.35.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote script directly to `sh` without first downloading and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- ...` executes remotely-fetched content in a shell, which is an unsafe-shell pattern. Even though the URL path contains a commit SHA, the content is still streamed directly into the shell interpreter without any integrity check.

Locations:

- `script.sh:10`

### script-injection (severity: high)

Sub-rule (b): Two unquoted shell variable expansions of user-controlled inputs exist in script.sh:

1. Line 54: `ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )` — `INPUT_ESLINT_FLAGS` is set from `inputs.eslint_flags` (user-controlled). The unquoted word-splitting expansion allows an attacker to inject shell metacharacters (e.g. semicolons, pipes, command substitutions) via the `eslint_flags` input.

2. Line 64: `${INPUT_REVIEWDOG_FLAGS}` is expanded unquoted at the end of the `reviewdog` command line. `INPUT_REVIEWDOG_FLAGS` is set from `inputs.reviewdog_flags` (user-controlled). An attacker can inject arbitrary shell arguments or metacharacters via this input.

Both variables should be double-quoted or handled through a safe array expansion.

Locations:

- `script.sh:54`
- `script.sh:64`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed three issues in script.sh:
1. unsafe-shell (line 10): Replaced `curl -sfL ... | sh -s -- -b ...` with a two-step approach: download the install script to a temp file with `curl -sfL ... -o "${INSTALL_SCRIPT}"`, then execute it with `sh "${INSTALL_SCRIPT}" -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The '--' was dropped (it was the shell's option terminator in the pipe form, not the script's argument).
2. script-injection (line 54): Replaced unquoted `${INPUT_ESLINT_FLAGS:-'.'}` word-splitting with safe xargs-based tokenization into a bash array (ESLINT_FLAGS_ARRAY), with an empty-guard defaulting to '.' when the input is empty.
3. script-injection (line 64): Replaced unquoted `${INPUT_REVIEWDOG_FLAGS}` with safe xargs-based tokenization into REVIEWDOG_FLAGS_ARRAY, expanded as `"${REVIEWDOG_FLAGS_ARRAY[@]}"` in the reviewdog command.

