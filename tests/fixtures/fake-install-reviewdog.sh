#!/bin/sh
# Fake reviewdog install script
# Usage: sh fake-install-reviewdog.sh -b <bindir> <version>
# Installs a fake reviewdog binary into <bindir>

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
  BINDIR="/usr/local/bin"
fi

mkdir -p "$BINDIR"

cat > "$BINDIR/reviewdog" << 'EOF'
#!/bin/sh
# Fake reviewdog: reads stdin and exits 0
cat > /dev/null
exit 0
EOF

chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog to $BINDIR/reviewdog"
