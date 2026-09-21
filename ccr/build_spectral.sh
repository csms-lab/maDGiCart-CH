#!/bin/bash
# Build the spectral-integrator worktree inside madg-gcc-fftw.sif.
# New file for the spectral-integrator validation work, 2026-08-31.
set -uo pipefail
BASE=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
BUILD=$BASE/maDGiCart-CH-gcc-build-spectral
SRC=$BASE/maDGiCart-CH-spectral
SIF=$BASE/madg-gcc-fftw.sif
mkdir -p "$BUILD"
exec > "$BUILD/build_spectral.log" 2>&1
echo "[$(date)] host=$(hostname) start"
if ! command -v apptainer >/dev/null 2>&1; then
  module load apptainer 2>/dev/null || true
fi
apptainer exec -B /projects:/projects "$SIF" bash -c "
  set -e
  cd $BUILD
  cmake -DCMAKE_BUILD_TYPE=Release -DMADG_USE_OPENMP=ON $SRC
  cmake --build . -j 8
"
rc=$?
echo "[$(date)] BUILD_DONE rc=$rc"
echo $rc > "$BUILD/.build_rc"
