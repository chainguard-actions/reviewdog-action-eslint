<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.36.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.36.0** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remotely fetched script directly to `sh` without first saving and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/.../install.sh | sh -s -- ...` executes whatever the remote server returns, enabling a supply-chain attack if the remote content is tampered with.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Sub-rule (b): `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"` expands the workflow-controllable env var `$INPUT_ESLINT_FLAGS` (sourced from `inputs.eslint_flags`) unquoted inside `eval`. An attacker-controlled value such as `); malicious_command; (` would be executed as a shell command. The `eval` call is explicitly noted as intentional in a comment, but it still constitutes a script-injection risk for any caller that does not fully trust the `eslint_flags` input.

Locations:

- `script.sh:56`

### script-injection (severity: high)

Sub-rule (b): `${INPUT_REVIEWDOG_FLAGS}` is passed unquoted as the last argument to the `reviewdog` command. `$INPUT_REVIEWDOG_FLAGS` is set from `inputs.reviewdog_flags` (workflow-controllable). The unquoted expansion allows the shell to perform word-splitting and interpret metacharacters (`;`, `|`, `&`, `$(...)`, etc.) from the value, enabling command injection.

Locations:

- `script.sh:65`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed three findings in hardened/action/script.sh:
1. unsafe-shell (line 11): Replaced `curl ... | sh -s -- -b ...` with downloading the install script to a temp file via `curl ... -o "${INSTALL_SCRIPT}"` and executing it with `sh "${INSTALL_SCRIPT}" -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The `--` was dropped as required since we're no longer piping to sh.
2. script-injection/eval (line 56): Replaced `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"` with a safe xargs-based tokenization loop that splits the flags into an array without executing arbitrary shell commands.
3. script-injection/unquoted (line 65): Replaced the unquoted `${INPUT_REVIEWDOG_FLAGS}` expansion with an xargs-based tokenization into `REVIEWDOG_FLAGS_ARRAY`, then expanded it as `"${REVIEWDOG_FLAGS_ARRAY[@]}"` to prevent word-splitting and metacharacter injection.

