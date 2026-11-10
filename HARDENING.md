<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-eslint/v1.36.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-eslint/v1.36.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh, run by the composite action's run: step, pipes remote content straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the script still runs without being saved to a file first. Download it to a file, check it (for example with a checksum), then run it as a separate step.

Locations:

- `script.sh:11`

### script-injection (severity: high)

Rule (a)/(b) via the entrypoint script: script.sh runs the workflow-controlled input `eslint_flags` through eval: `eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"`. INPUT_ESLINT_FLAGS comes from `${{ inputs.eslint_flags }}`. eval runs any `;`, `$(...)` or backticks in the value as commands, so whoever controls the input can run arbitrary commands on the runner. Parse the flags without eval, for example by splitting on whitespace into an array with a SC2206 directive.

Locations:

- `script.sh:59`

### script-injection (severity: high)

Rule (b): in script.sh the workflow-controlled input reviewdog_flags is expanded without quotes as a command argument: `      ${INPUT_REVIEWDOG_FLAGS}`. The value comes from `${{ inputs.reviewdog_flags }}`. It is not an array assignment, so the SC2206 exemption does not apply. A `# shellcheck disable=SC2086` comment is present, but it does not make this expansion safe. Quote it, or split it into an array with an explicit assignment such as `REVIEWDOG_FLAGS_ARRAY=(${INPUT_REVIEWDOG_FLAGS})` plus a shellcheck SC2206 directive, then pass "${REVIEWDOG_FLAGS_ARRAY[@]}".

Locations:

- `script.sh:77`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed action.yml without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/action.yml b/action.yml
index a638edc..433ffe8 100644
--- a/action.yml
+++ b/action.yml
@@ -1,5 +1,5 @@
 name: 'Run eslint with reviewdog'
-description: '🐶 Run eslint with reviewdog on pull requests to improve code review experience.'
+description: "\U0001F436 Run eslint with reviewdog on pull requests to improve code review experience."
 author: 'haya14busa (reviewdog)'
 inputs:
   github_token:
@@ -68,6 +68,23 @@ inputs:
 runs:
   using: 'composite'
   steps:
     - run: $GITHUB_ACTION_PATH/script.sh
       shell: bash
       env:

```

Locations:

- `action.yml`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed script.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/script.sh b/script.sh
index 5bbf876..81ff69c 100755
--- a/script.sh
+++ b/script.sh
@@ -8,7 +8,10 @@ export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
 ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"
 
 echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
-curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+INSTALL_SCRIPT="$(mktemp)"
+curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh -o "${INSTALL_SCRIPT}"
+sh "${INSTALL_SCRIPT}" -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
+rm -f "${INSTALL_SCRIPT}"
 echo '::endgroup::'
 
 if ! npx --no-install -c 'eslint --version'; then
@@ -51,12 +54,15 @@ if [ "${INPUT_ONLY_CHANGED}" = "true" ]; then
 fi
 
 # eslint_flags may contain quoted arguments (e.g. globs such as
-# "src/**/*.{ts,tsx}"). Use eval so the shell performs word splitting and
-# quote removal on the value, matching the v1.34.x behavior where the flags
-# were interpolated into a shell command string. INPUT_ESLINT_FLAGS is
-# provided by the (trusted) workflow author.
-# shellcheck disable=SC2294
-eval "ESLINT_FLAGS_ARRAY=( ${INPUT_ESLINT_FLAGS:-'.'} )"
+# "src/**/*.{ts,tsx}"). Use xargs-based tokenization so the shell performs
+# word splitting and quote removal on the value without executing arbitrary
+# shell commands via eval.
+ESLINT_FLAGS_ARRAY=()
+_eslint_flags_input="${INPUT_ESLINT_FLAGS:-'.'}"
+if [ -n "${_eslint_flags_input}" ]; then
+  while IFS= read -r -d '' t; do ESLINT_FLAGS_ARRAY+=("$t"); done \
+    < <(printf '%s' "${_eslint_flags_input}" | xargs printf '%s\0')
+fi
 
 ESLINT_ARGS=(-f "${ESLINT_FORMATTER}")
 ESLINT_ARGS+=("${ESLINT_FLAGS_ARRAY[@]}")
@@ -64,8 +70,13 @@ if [ -n "${CHANGED_FILES+x}" ]; then
   ESLINT_ARGS+=("${CHANGED_FILES[@]}")
 fi
 
+REVIEWDOG_FLAGS_ARRAY=()
+if [ -n "${INPUT_REVIEWDOG_FLAGS}" ]; then
+  while IFS= read -r -d '' t; do REVIEWDOG_FLAGS_ARRAY+=("$t"); done \
+    < <(printf '%s' "${INPUT_REVIEWDOG_FLAGS}" | xargs printf '%s\0')
+fi
+
 echo '::group:: Running eslint with reviewdog 🐶 ...'
-# shellcheck disable=SC2086
 npx --no-install eslint "${ESLINT_ARGS[@]}" \
   | reviewdog -f=rdjson \
       -name="${INPUT_TOOL_NAME}" \
@@ -74,7 +85,7 @@ npx --no-install eslint "${ESLINT_ARGS[@]}" \
       -fail-level="${INPUT_FAIL_LEVEL}" \
       -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
       -level="${INPUT_LEVEL}" \
-      ${INPUT_REVIEWDOG_FLAGS}
+      "${REVIEWDOG_FLAGS_ARRAY[@]}"
 
 reviewdog_rc=$?
 echo '::endgroup::'

```

Locations:

- `script.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, prior-fix

**Notes:**

script.sh: the reviewdog installer is now saved to a mktemp file and then run as `sh "$INSTALL_SCRIPT" -b "$TEMP_PATH" "$REVIEWDOG_VERSION"`. I dropped `-s --`, which only mattered when the script came in on stdin. No checksum is checked, but the URL is pinned to a commit. The `eval` of eslint_flags is gone. The flags are now split with the quote-aware xargs method, keeping the quote removal upstream's eval did: an `xargs -r true` check rejects an unmatched quote, and the split runs `sh -c 'printf "%s\0" "$@"' sh` with an empty-value guard. The default is still '.'. One difference from upstream: eval also expanded unquoted globs and braces in the shell, and the new split passes them to eslint as literal text. reviewdog_flags is now built as an array assigned unquoted, which splits and globs exactly like upstream's unquoted $INPUT_REVIEWDOG_FLAGS, then passed as "${REVIEWDOG_FLAGS_ARRAY[@]}". I did not use xargs here because reviewdog reads its input on stdin. action.yml: re-applied the earlier escaped-emoji description. The earlier patch's diff was cut off, and the visible part has no other security changes.

