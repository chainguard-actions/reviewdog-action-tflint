#!/bin/bash
# Fake reviewdog install script.
# Called with: [-b <bindir>] [<version>]
# Creates a fake reviewdog binary that reads stdin and exits 0.
BINDIR=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-b" ]; then
    BINDIR="$2"
    shift 2
  else
    shift
  fi
done

if [ -z "$BINDIR" ]; then
  BINDIR="/usr/local/bin"
fi

mkdir -p "$BINDIR"
printf '#!/bin/bash\n# Fake reviewdog: reads stdin and exits 0\ncat > /dev/null\nexit 0\n' > "$BINDIR/reviewdog"
chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog to $BINDIR/reviewdog"
