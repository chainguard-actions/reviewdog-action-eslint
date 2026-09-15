#!/bin/sh
# Fake curl: serve a canned payload for the reviewdog install URL, supporting both
# "curl URL | sh" (payload to stdout) and the hardened "curl -o FILE URL"
# (payload written to FILE). A stdout-only mock breaks the hardened action.

FAKE_INSTALL_SCRIPT="$GITHUB_WORKSPACE/tests/fixtures/fake-install-reviewdog.sh"

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
      cat "$FAKE_INSTALL_SCRIPT" > "$out"
    else
      cat "$FAKE_INSTALL_SCRIPT"
    fi
    exit 0
    ;;
esac

# Fall through to real curl for other URLs
exec /usr/bin/curl "$@"
