#!/bin/bash
# Make the files of this directory the ones CCR uses.
#
# The solver's run wrappers, build scripts, container recipes and the GPU check job live in
# this directory of the repository. On CCR they are reached through the directory
#     /projects/academic/kreyes3/BNL-M2DT/maDGiCart/
# whose absolute paths the ensemble builder and the run records name. This script puts a
# symbolic link there for every file here, so that a `git pull` in the clone is all it takes
# to update CCR, and nothing on CCR can drift from the repository unnoticed.
#
# It never deletes. A regular file already at the destination is moved into
# loose-scripts-before-<date>/ beside it, and only then replaced by the link. A link that
# already points here is left alone. Run it on a CCR login node, from anywhere.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
[ -d "$DEST" ] || { echo "ERROR: $DEST does not exist; this script is for CCR." >&2; exit 2; }
ASIDE="$DEST/loose-scripts-before-$(date +%Y.%m.%d)"
for f in "$HERE"/*; do
  name=$(basename "$f")
  case "$name" in install_links.sh|README.md) continue ;; esac
  target="$DEST/$name"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$f" ]; then
    echo "ok       $name"
  elif [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$ASIDE"
    if cmp -s "$target" "$f"; then note="identical to the repository's"; else note="DIFFERS from the repository's"; fi
    mv "$target" "$ASIDE/$name"
    ln -s "$f" "$target"
    echo "linked   $name   (the file that was there, $note, is in $(basename "$ASIDE")/)"
  else
    ln -s "$f" "$target"
    echo "linked   $name   (new)"
  fi
done
