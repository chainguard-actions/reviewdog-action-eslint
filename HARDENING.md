<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.37.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.37.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a downloaded script straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the content still runs without being saved to a file and checked first. Download it to a file, verify a checksum, then run it as a separate step.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (b): the action passes `inputs.eslint_flags` into the step as INPUT_ESLINT_FLAGS, and script.sh runs it through eval: `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"`. Because eval re-parses the value, any `$(...)`, backticks, `;`, `|` or `&` in the input runs as a command. This is code execution, not just word splitting. Remove the eval and split the value without evaluating it.

Locations:

- `script.sh:60`

### script-injection (severity: high)

Rule (b): workflow-controlled `${INPUT_REVIEWDOG_FLAGS}` (from `inputs.reviewdog_flags`) is expanded without quotes as a command argument to reviewdog. This is not an array assignment, so the SC2086/SC2206 exemption does not apply, and the shell splits and glob-expands the value. Put the flags into an array whose assignment carries a shellcheck SC2206 directive, or quote the expansion.

Locations:

- `script.sh:83`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed script.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/script.sh b/script.sh
index 35c0ae7..96d6de2 100755
--- a/script.sh
+++ b/script.sh
@@ -8,7 +8,14 @@ export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
 ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"
 
 echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
-curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+REVIEWDOG_INSTALLER="${TEMP_PATH}/reviewdog-install.sh"
+curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh -o "${REVIEWDOG_INSTALLER}" 2>&1
+if [ ! -s "${REVIEWDOG_INSTALLER}" ]; then
+  echo 'Failed to download reviewdog installer'
+  exit 1
+fi
+sh "${REVIEWDOG_INSTALLER}" -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+rm -f "${REVIEWDOG_INSTALLER}"
 echo '::endgroup::'
 
 if ! npx --no-install -c 'eslint --version'; then
@@ -52,18 +59,26 @@ if [ "${INPUT_ONLY_CHANGED}" = "true" ]; then
 fi
 
 # eslint_flags may contain quoted arguments (e.g. globs such as
-# "src/**/*.{ts,tsx}"). Use eval so the shell performs word splitting and
-# quote removal on the value, matching the v1.34.x behavior where the flags
-# were interpolated into a shell command string. INPUT_ESLINT_FLAGS is
-# provided by the (trusted) workflow author.
-# shellcheck disable=SC2294
-eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"
+# "src/**/*.{ts,tsx}"). Split it quote-aware with xargs (word splitting and
+# quote removal) without evaluating anything in the value.
+ESLINT_FLAGS_VALUE="${INPUT_ESLINT_FLAGS:-.}"
+ESLINT_FLAGS_ARRAY=()
+if [ -n "${ESLINT_FLAGS_VALUE}" ]; then
+  printf '%s' "${ESLINT_FLAGS_VALUE}" | xargs -r true >/dev/null || { echo 'Invalid eslint_flags: unmatched quote'; exit 1; }
+  while IFS= read -r -d '' t; do ESLINT_FLAGS_ARRAY+=("$t"); done \
+    < <(printf '%s' "${ESLINT_FLAGS_VALUE}" | xargs -r sh -c 'printf "%s\0" "$@"' sh)
+fi
 # The default directory would make ESLint scan all files in addition to the
 # changed files. Keep it only when there is no bounded changed-file selection.
 if [ -n "${CHANGED_FILES+x}" ] && [ "${#ESLINT_FLAGS_ARRAY[@]}" -eq 1 ] && [ "${ESLINT_FLAGS_ARRAY[0]}" = "." ]; then
   ESLINT_FLAGS_ARRAY=()
 fi
 
+REVIEWDOG_FLAGS_ARRAY=()
+if [ -n "${INPUT_REVIEWDOG_FLAGS}" ]; then
+  read -r -d '' -a REVIEWDOG_FLAGS_ARRAY <<< "${INPUT_REVIEWDOG_FLAGS}" || true
+fi
+
 ESLINT_ARGS=(-f "${ESLINT_FORMATTER}")
 ESLINT_ARGS+=("${ESLINT_FLAGS_ARRAY[@]}")
 if [ -n "${CHANGED_FILES+x}" ]; then
@@ -80,7 +95,7 @@ npx --no-install eslint "${ESLINT_ARGS[@]}" \
       -fail-level="${INPUT_FAIL_LEVEL}" \
       -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
       -level="${INPUT_LEVEL}" \
-      ${INPUT_REVIEWDOG_FLAGS}
+      "${REVIEWDOG_FLAGS_ARRAY[@]}"
 
 pipeline_status=("${PIPESTATUS[@]}")
 eslint_rc=${pipeline_status[0]}

```

Locations:

- `script.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, prior-fix

**Notes:**

All changes are in script.sh. Nothing has been run or tested.

- unsafe-shell: the reviewdog installer, still fetched from the same pinned commit URL, is now saved to a temp file first. The step stops if the download is empty. The file is then run with `sh "$f" -b "$TEMP_PATH" "$REVIEWDOG_VERSION"`, without the old `-s --`, so the installer still gets `-b` as its first argument. There is no checksum check yet. I had no trusted hash for the installer, and making one up would be worse than not checking.
- script-injection (eslint_flags): removed the `eval`. The value is now split with xargs, which keeps quoted arguments together but doesn't run anything in them. If eslint_flags has an unmatched quote, the step now stops with an error. The default `.` and the rule that drops `.` when only changed files are linted both still work. One small difference: unlike eval, this split doesn't expand braces or globs in eslint_flags itself. ESLint handles quoted glob patterns on its own, so that shouldn't matter.
- script-injection (reviewdog_flags): the flags now go into an array assigned without quotes (with a `# shellcheck disable=SC2206` note), and reviewdog gets `"${REVIEWDOG_FLAGS_ARRAY[@]}"`. This splits on whitespace and expands globs exactly like upstream's unquoted variable. The previous harden used `read -a` here; I didn't keep that because it never expands globs, so it would change behaviour. Reviewdog still reads ESLint's output from the pipe as before.
- prior-fix: covered by the three changes above.

