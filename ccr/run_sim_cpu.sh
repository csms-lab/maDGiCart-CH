#!/bin/bash
# Run the CPU (gcc) maDGiCart-CH simulator, selecting the build variant.
#   Usage: run_sim_cpu.sh <prod|dev> [maDGiCart args...]
#   prod = original integer-division domain sizing (matches committed code)
#   dev  = double-division fix on program_options.hpp:44,49
# The .sif is identical for both; the variant is selected purely by which host
# build dir is bound to the canonical internal path the binary was linked against.
# Must run where apptainer/singularity exists (compute/compile node, not login).
set -euo pipefail
VARIANT="${1:?usage: run_sim_cpu.sh <prod|dev> [args...]}"; shift || true
case "$VARIANT" in prod|dev) ;; *) echo "ERROR: variant must be prod or dev, got '$VARIANT'" >&2; exit 2;; esac
BASE=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
BUILD="$BASE/maDGiCart-CH-gcc-build-$VARIANT"
SIF="$BASE/madg-gcc-amd64.sif"
[ -d "$BUILD" ] || { echo "ERROR: no build dir $BUILD" >&2; exit 1; }
APP=$(command -v apptainer || command -v singularity) || { echo "ERROR: no apptainer/singularity in PATH" >&2; exit 2; }
exec "$APP" exec --env LC_ALL=C \
  --bind "$BASE/maDGiCart-CH:/M2DT/maDGiCart/maDGiCart-CH" \
  --bind "$BUILD:/M2DT/maDGiCart/maDGiCart-CH-gcc-build" \
  --bind /scratch:/scratch \
  "$SIF" /M2DT/maDGiCart/maDGiCart-CH-gcc-build/maDGiCart "$@"
