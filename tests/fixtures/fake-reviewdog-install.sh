#!/bin/sh
# Fake reviewdog install script
# Usage: sh install.sh -b <bindir> <version>
BINDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -b) BINDIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$BINDIR" ]; then
  BINDIR="/usr/local/bin"
fi

mkdir -p "$BINDIR"

cat > "$BINDIR/reviewdog" << 'REVIEWDOG_EOF'
#!/bin/sh
# Fake reviewdog binary for testing
# Reads stdin (eslint rdjson output) and exits 0
cat > /dev/null
exit 0
REVIEWDOG_EOF

chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog to $BINDIR/reviewdog"
