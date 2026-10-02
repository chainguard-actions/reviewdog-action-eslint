#!/bin/sh
# Fake curl: intercepts reviewdog install.sh URL and serves fake install script.
# Supports both "curl URL | sh" (stdout) and hardened "curl -o FILE URL" forms.

out=""
prev=""
for arg in "$@"; do
  case "$prev" in
    -o|--output) out="$arg" ;;
  esac
  prev="$arg"
done

case "$*" in
  *reviewdog*)
    if [ -n "$out" ]; then
      cat "$GITHUB_WORKSPACE/tests/fixtures/fake-install-reviewdog.sh" > "$out"
    else
      cat "$GITHUB_WORKSPACE/tests/fixtures/fake-install-reviewdog.sh"
    fi
    exit 0
    ;;
esac

# Fall through to real curl for other URLs
exec /usr/bin/curl "$@"
