#!/bin/sh
# Fake reviewdog install script - installs a reviewdog that exits 1
# Used for testing fail_level behavior
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
# Fake reviewdog binary that exits 1 (simulates finding issues with fail_level=error)
cat > /dev/null
exit 1
REVIEWDOG_EOF

chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog (exit 1) to $BINDIR/reviewdog"
