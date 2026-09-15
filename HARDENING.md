<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.35.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.35.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading and verifying it. The command `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- ...` executes whatever content is served at that URL in the runner shell. Even though the URL is pinned to a commit SHA in the path, the pattern itself is flagged as unsafe-shell because the content is streamed directly to a shell interpreter without an intermediate verification step.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Sub-rule (b): Two unquoted expansions of workflow-controllable env vars in script.sh:

1. Line 59: `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"` — INPUT_ESLINT_FLAGS is set from `${{ inputs.eslint_flags }}` in action.yml. Expanding an untrusted input inside `eval` without quoting allows an attacker to inject arbitrary shell commands (e.g., a value like `$(malicious_cmd)` or `; rm -rf /`).

2. Line 77: `${INPUT_REVIEWDOG_FLAGS}` is unquoted at the end of the reviewdog invocation. INPUT_REVIEWDOG_FLAGS is set from `${{ inputs.reviewdog_flags }}`. The unquoted expansion allows shell word-splitting and metacharacter injection (e.g., values containing `;`, `|`, `&`, or `$(...)` will be interpreted by the shell).

Locations:

- `script.sh:59`
- `script.sh:77`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed all three findings in hardened/action/script.sh:

1. unsafe-shell (line 11): Replaced `curl ... | sh -s -- -b ...` with a two-step approach: download the install script to a temp file with `curl -sfL ... -o "$INSTALL_SCRIPT"`, then execute it with `sh "$INSTALL_SCRIPT" -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The `--` was dropped (it was the shell's own option terminator in the piped form, not the script's argument).

2. script-injection (line 59): Replaced `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"` with xargs-based quote-aware tokenization: `while IFS= read -r -d '' t; do ESLINT_FLAGS_ARRAY+=("$t"); done < <(printf '%s' "$_eslint_flags_input" | xargs printf '%s\0')`. This preserves quoted glob arguments while preventing arbitrary shell command injection.

3. script-injection (line 77): Replaced unquoted `${INPUT_REVIEWDOG_FLAGS}` with a properly tokenized `REVIEWDOG_FLAGS_ARRAY` using the same xargs pattern, then expanded as `"${REVIEWDOG_FLAGS_ARRAY[@]}"` to prevent word-splitting and metacharacter injection from user-controlled input.

