#!/bin/bash
# Builds madg-gcc-fftw.sif from madg-gcc.def. Run on the CCR compile server.
# Mirrors build_cuda_sif.sh: tmpdir on node-local /scratch (never /projects),
# shared apptainer cache, fakeroot without the injected faked.
set -e
M=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
WORK=$(mktemp -d /scratch/madg_gccbuild_XXXXXX)
trap 'rm -rf "$WORK"' EXIT
unset SINGULARITY_CACHEDIR SINGULARITY_TMPDIR SINGULARITY_LOCALCACHEDIR APPTAINER_LOCALCACHEDIR
export APPTAINER_CACHEDIR=/projects/academic/kreyes3/Environments/apptainer_cache
export APPTAINER_TMPDIR="$WORK"
echo "[$(date)] host=$(hostname) TMPDIR=$WORK building from $M/madg-gcc.def"
apptainer build --fakeroot --ignore-fakeroot-command "$WORK/madg-gcc-fftw.sif" "$M/madg-gcc.def"
mv "$WORK/madg-gcc-fftw.sif" "$M/madg-gcc-fftw.sif"
echo "[$(date)] BUILD COMPLETE: $(ls -la "$M/madg-gcc-fftw.sif")"
