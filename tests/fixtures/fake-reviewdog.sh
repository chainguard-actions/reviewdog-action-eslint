#!/bin/sh
# Fake reviewdog: reads stdin (eslint rdjson output) and exits 0
# Accepts all reviewdog flags and ignores them
cat > /dev/null
exit 0
