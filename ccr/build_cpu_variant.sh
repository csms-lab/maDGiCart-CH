#!/bin/bash
#SBATCH --job-name=madg_cpu_build
#SBATCH --cluster=ub-hpc
#SBATCH --partition=general-compute
#SBATCH --qos=general-compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
set -uo pipefail
VARIANT="$1"; SEED="$2"
BASE=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
DEST="$BASE/maDGiCart-CH-gcc-build-$VARIANT"
SIF="$BASE/madg-gcc-amd64.sif"
echo "[$(date)] host=$(hostname) VARIANT=$VARIANT SEED=$SEED"
if ! command -v apptainer >/dev/null 2>&1 && ! command -v singularity >/dev/null 2>&1; then
  module load apptainer 2>/dev/null || module load singularity 2>/dev/null || true
fi
APP=$(command -v apptainer || command -v singularity)
echo "container runtime: ${APP:-NONE}"
[ -z "$APP" ] && { echo "FATAL: no apptainer/singularity"; exit 2; }
if [ ! -d "$DEST" ]; then
  echo "[$(date)] seeding $(basename "$DEST") from $SEED (cp -a)"
  cp -a "$BASE/$SEED" "$DEST"
fi
export APPTAINER_CACHEDIR=/projects/academic/kreyes3/Environments/apptainer_cache
echo "[$(date)] building maDGiCart in $(basename "$DEST")"
"$APP" exec \
  --bind "$BASE/maDGiCart-CH:/M2DT/maDGiCart/maDGiCart-CH" \
  --bind "$DEST:/M2DT/maDGiCart/maDGiCart-CH-gcc-build" \
  --bind /scratch:/scratch \
  --env LC_ALL=C \
  "$SIF" bash -c '
    set -e
    cd /M2DT/maDGiCart/maDGiCart-CH-gcc-build
    echo "=== toolchain ==="; g++ --version | head -1; cmake --version | head -1
    echo "=== cmake --build --target maDGiCart ==="
    cmake --build . --target maDGiCart -j "$(nproc)"
    echo "=== artifact ==="; ls -la maDGiCart; file maDGiCart
  '
rc=$?
echo "[$(date)] BUILD_DONE variant=$VARIANT rc=$rc"
exit $rc
