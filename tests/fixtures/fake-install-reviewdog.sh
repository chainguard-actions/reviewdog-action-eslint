#!/bin/sh
# Fake reviewdog install script
# Usage: sh fake-install-reviewdog.sh -b <bindir> <version>
# Parses -b <bindir> and installs a fake reviewdog there

BINDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -b)
      BINDIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$BINDIR" ]; then
  echo "Error: -b <bindir> is required" >&2
  exit 1
fi

mkdir -p "$BINDIR"

# Create a fake reviewdog binary
cat > "$BINDIR/reviewdog" << 'REVIEWDOG_EOF'
#!/bin/sh
# Fake reviewdog: consume stdin and exit 0
cat > /dev/null
exit 0
REVIEWDOG_EOF

chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog to $BINDIR/reviewdog"
