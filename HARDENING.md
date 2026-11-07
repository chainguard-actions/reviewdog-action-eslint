<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.37.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.37.0** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh, the script the composite action runs, downloads remote content and pipes it straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the content still runs without being saved to a file and checked first.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b) / evaluated input: script.sh runs the workflow-controlled input eslint_flags (env INPUT_ESLINT_FLAGS) through eval: `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"`. Shell metacharacters in the value, such as $(...), backticks or `)`, get executed. This allows arbitrary command execution from the action input.

Locations:

- `script.sh:60`

### script-injection (severity: high)

Rule (b): the workflow-controlled input reviewdog_flags is expanded without quotes as an argument to reviewdog: `${INPUT_REVIEWDOG_FLAGS}`. This lets the shell split it into words and expand globs on untrusted data.

Locations:

- `script.sh:82`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

script.sh: (1) The reviewdog installer is now saved to a temp file with curl -o. The script stops if that file is empty, otherwise runs it with `sh "$file" -b "$TEMP_PATH" "$REVIEWDOG_VERSION"`. The '-s --' from the pipe form is dropped, so the installer still gets '-b' as its first argument. (2) The eval of eslint_flags is replaced by a quote-aware xargs split into an array. Quoted globs are still accepted and nothing in the value is run. It defaults to '.' and stops on an unmatched quote. (3) reviewdog_flags is split on whitespace into an array with `read -r -d '' -a`, which keeps upstream's splitting without globbing. I didn't use xargs there because reviewdog reads eslint's output on stdin.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed the parse error in script.sh around line 73. Two pieces of text had been run together there: the 'if [ ... -eq' condition swallowed 'REVIEWDOG_FLAGS_ARRAY=()', and a 'npxRGS=(...)' line stood where 'ESLINT_ARGS=(...)' belonged. A duplicate group echo was also left in that area. Rebuilt it as: (1) when a changed-file list exists and eslint_flags is just the default '.', clear ESLINT_FLAGS_ARRAY (this matches script_changed_test.sh); (2) build REVIEWDOG_FLAGS_ARRAY with a whitespace split (read -r -d '' -a ... || true); (3) start the eslint arguments with ESLINT_ARGS=(-f "$ESLINT_FORMATTER"). Nothing else changed.

