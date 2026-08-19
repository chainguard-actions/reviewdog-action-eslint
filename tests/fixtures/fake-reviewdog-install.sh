#!/bin/sh
# Fake reviewdog install script
# Parses -b <bindir> and installs a fake reviewdog binary there
BINDIR=""
prev=""
for arg in "$@"; do
  case "$prev" in
    -b) BINDIR="$arg" ;;
  esac
  prev="$arg"
done

if [ -z "$BINDIR" ]; then
  BINDIR="/usr/local/bin"
fi

mkdir -p "$BINDIR"
cat > "$BINDIR/reviewdog" << 'REVIEWDOG_EOF'
#!/bin/sh
# Fake reviewdog: consume stdin and exit 0
cat > /dev/null
exit 0
REVIEWDOG_EOF
chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog to $BINDIR/reviewdog"
