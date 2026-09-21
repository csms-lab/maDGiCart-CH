#!/bin/bash
# Run the spectral-integrator maDGiCart-CH build (dct_si / fft_si capable).
#   Usage: run_sim_spectral.sh [maDGiCart args...]
# Mirrors run_sim_cpu.sh's conventions, with two differences dictated by this build:
#   * image is madg-gcc-fftw.sif (FFTW baked in; madg-gcc-amd64.sif has no FFTW), and
#   * the spectral binary's RUNPATH embeds the real host build path
#     (/projects/.../maDGiCart-CH-gcc-build-spectral), so the source and build trees
#     are bound at their own host paths instead of the canonical /M2DT internal path.
# Output files land in the caller's working directory (apptainer binds the CWD).
# Must run where apptainer/singularity exists (compute/compile node, not login).
set -euo pipefail
BASE=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
BUILD="$BASE/maDGiCart-CH-gcc-build-spectral"
SIF="$BASE/madg-gcc-fftw.sif"
[ -d "$BUILD" ] || { echo "ERROR: no build dir $BUILD" >&2; exit 1; }
[ -x "$BUILD/maDGiCart" ] || { echo "ERROR: no binary $BUILD/maDGiCart" >&2; exit 1; }
[ -f "$SIF" ] || { echo "ERROR: no image $SIF" >&2; exit 1; }
APP=$(command -v apptainer || command -v singularity) || { echo "ERROR: no apptainer/singularity in PATH" >&2; exit 2; }
exec "$APP" exec --env LC_ALL=C \
  --bind "$BASE/maDGiCart-CH-spectral:$BASE/maDGiCart-CH-spectral" \
  --bind "$BUILD:$BUILD" \
  --bind /scratch:/scratch \
  "$SIF" "$BUILD/maDGiCart" "$@"
