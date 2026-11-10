#!/usr/bin/env bash

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
ESLINT_FORMATTER="${GITHUB_ACTION_PATH}/eslint-formatter-rdjson/index.js"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
REVIEWDOG_INSTALLER="${TEMP_PATH}/reviewdog-install.sh"
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh -o "${REVIEWDOG_INSTALLER}" 2>&1
if [ ! -s "${REVIEWDOG_INSTALLER}" ]; then
  echo 'Failed to download reviewdog installer'
  exit 1
fi
sh "${REVIEWDOG_INSTALLER}" -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
rm -f "${REVIEWDOG_INSTALLER}"
echo '::endgroup::'

if ! npx --no-install -c 'eslint --version'; then
  echo '::group:: Running `npm install` to install eslint ...'
  npm install || exit $?
  echo '::endgroup::'
fi

echo "eslint version:$(npx --no-install -c 'eslint --version')"

if [ "${INPUT_ONLY_CHANGED}" = "true" ]; then
  echo '::group:: Getting changed files list'

  if [ -z "${BASE_REF}" ] || [ -z "${HEAD_REF}" ]; then
    echo 'BASE_REF or HEAD_REF is not available. Running eslint on all files.'
  else
    if ! git cat-file -e "${BASE_REF}"; then
      git fetch --depth 1 origin "${BASE_REF}"
    fi

    git diff --relative --diff-filter=d --name-only -z "${BASE_REF}..${HEAD_REF}" > "${TEMP_PATH}/changed-files" || exit $?
    CHANGED_FILES=()
    while IFS= read -r -d '' file; do
      CHANGED_FILES+=("${file}")
    done < "${TEMP_PATH}/changed-files"

    if (( ${#CHANGED_FILES[@]} == 0 )); then
      echo 'No changed files, skipping'
      exit 0
    fi

    printf '%s\n' "${CHANGED_FILES[@]}"

    if (( ${#CHANGED_FILES[@]} > 100 )); then
      echo "More than 100 changed files (${#CHANGED_FILES[@]}), running eslint on all files"
      unset CHANGED_FILES
    fi
  fi

  echo '::endgroup::'
fi

# eslint_flags may contain quoted arguments (e.g. globs such as
# "src/**/*.{ts,tsx}"). Split it quote-aware with xargs (word splitting and
# quote removal) without evaluating anything in the value.
ESLINT_FLAGS_VALUE="${INPUT_ESLINT_FLAGS:-.}"
ESLINT_FLAGS_ARRAY=()
if [ -n "${ESLINT_FLAGS_VALUE}" ]; then
  printf '%s' "${ESLINT_FLAGS_VALUE}" | xargs -r true >/dev/null || { echo 'Invalid eslint_flags: unmatched quote'; exit 1; }
  while IFS= read -r -d '' t; do ESLINT_FLAGS_ARRAY+=("$t"); done \
    < <(printf '%s' "${ESLINT_FLAGS_VALUE}" | xargs -r sh -c 'printf "%s\0" "$@"' sh)
fi
# The default directory would make ESLint scan all files in addition to the
# changed files. Keep it only when there is no bounded changed-file selection.
if [ -n "${CHANGED_FILES+x}" ] && [ "${#ESLINT_FLAGS_ARRAY[@]}" -eq 1 ] && [ "${ESLINT_FLAGS_ARRAY[0]}" = "." ]; then
  ESLINT_FLAGS_ARRAY=()
fi

# Same whitespace split and glob as upstream's unquoted ${INPUT_REVIEWDOG_FLAGS}.
# shellcheck disable=SC2206
REVIEWDOG_FLAGS_ARRAY=(${INPUT_REVIEWDOG_FLAGS})

ESLINT_ARGS=(-f "${ESLINT_FORMATTER}")
ESLINT_ARGS+=("${ESLINT_FLAGS_ARRAY[@]}")
if [ -n "${CHANGED_FILES+x}" ]; then
  ESLINT_ARGS+=("${CHANGED_FILES[@]}")
fi

echo '::group:: Running eslint with reviewdog 🐶 ...'
# shellcheck disable=SC2086
npx --no-install eslint "${ESLINT_ARGS[@]}" \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-level="${INPUT_FAIL_LEVEL}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      "${REVIEWDOG_FLAGS_ARRAY[@]}"

pipeline_status=("${PIPESTATUS[@]}")
eslint_rc=${pipeline_status[0]}
reviewdog_rc=${pipeline_status[1]}
echo '::endgroup::'
# ESLint uses 1 for lint findings, whose failure policy belongs to reviewdog.
# Configuration/internal errors (2), or a failed invocation, must still fail.
if [ "${eslint_rc}" -gt 1 ]; then
  exit "${eslint_rc}"
fi
exit $reviewdog_rc
