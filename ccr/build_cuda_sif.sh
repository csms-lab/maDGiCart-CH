#!/bin/bash
set -e
M=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
WORK=$(mktemp -d /scratch/madg_cudabuild_XXXXXX)
trap 'rm -rf "$WORK"' EXIT
unset SINGULARITY_CACHEDIR SINGULARITY_TMPDIR SINGULARITY_LOCALCACHEDIR APPTAINER_LOCALCACHEDIR
export APPTAINER_CACHEDIR=/projects/academic/kreyes3/Environments/apptainer_cache
export APPTAINER_TMPDIR="$WORK"
echo "[$(date)] host=$(hostname) TMPDIR=$WORK building from $M/madg-cuda.def"
apptainer build --fakeroot --ignore-fakeroot-command "$WORK/madg-cuda-sm89.sif" "$M/madg-cuda.def"
mv "$WORK/madg-cuda-sm89.sif" "$M/madg-cuda-sm89.sif"
echo "[$(date)] BUILD COMPLETE: $(ls -la "$M/madg-cuda-sm89.sif")"
