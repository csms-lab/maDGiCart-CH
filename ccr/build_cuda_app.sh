#!/bin/bash
# Build or rebuild the GPU (CUDA) build of maDGiCart-CH on CCR.
#
#   1. On a CCR login node, bring the solver clone to the commit to be built:
#        git -C /projects/academic/kreyes3/BNL-M2DT/maDGiCart/maDGiCart-CH -c core.fileMode=false pull --ff-only
#   2. From the login node:  ssh compile2
#   3. Run this script there. It writes build_cuda_app.<timestamp>.log beside itself.
#   4. Check the result on a GPU node:  sbatch check_cuda_build.slurm   (same directory)
#
# Rules this script enforces or relies on (each was learned by a failure, 2026-09-21):
#   - Compile on the compile server, never on a GPU node. The solver compiles its host code
#     with -march=native, so the build targets the processor it is compiled on. The build of
#     record has always been compiled on compile2 (AMD EPYC 9355P).
#   - Build in the build directory itself, never in a copy of it. cp gives every object file
#     a new timestamp, make then skips sources that changed before the copy, and the result
#     mixes old and new libraries (runs abort with std::bad_alloc).
#   - PETSc's configure step re-runs on every build and needs a TMPDIR that exists inside the
#     container; /tmp does.
#   - The container madg-cuda-sm89.sif needs no FFTW3: since solver commit 0cd3ec2 a GPU
#     build leaves the spectral integrators (fft_si, dct_si) out.
#   - The tree is bound at /M2DT, because the binary's library paths were fixed under that
#     name when the directory was first configured. run_sim_gpu.sh binds it the same way.
# This version replaces the script of 2026-06-02, kept as build_cuda_app.2026-06-02.sh.
set -uo pipefail
M=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
SRC=$M/maDGiCart-CH
BUILD=$M/maDGiCart-CH-cuda-build
SIF=$M/madg-cuda-sm89.sif
LOG=$M/build_cuda_app.$(date +%Y.%m.%d.%H%M%S).log

case "$(hostname)" in
  compile*) ;;
  *) echo "ERROR: run this on the compile server (ssh compile2 from a login node), not on $(hostname)." >&2; exit 2 ;;
esac
[ -f "$SIF" ] || { echo "ERROR: no container image $SIF" >&2; exit 2; }
[ -f "$BUILD/CMakeCache.txt" ] || echo "note: $BUILD is not configured yet; this will be a first build and takes about 20 minutes."
command -v apptainer >/dev/null 2>&1 || module load apptainer 2>/dev/null || true

exec > >(tee "$LOG") 2>&1
echo "[$(date)] host=$(hostname); $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //')"
echo "source commit: $(git -C $SRC rev-parse HEAD) on $(git -C $SRC rev-parse --abbrev-ref HEAD)"
changed=$(git -C $SRC -c core.fileMode=false status --porcelain | wc -l)
echo "source files changed against that commit: $changed"
if [ "$changed" -ne 0 ]; then echo "ERROR: the solver clone has uncommitted changes; a build must come from a commit."; exit 3; fi

hashes() { ( cd "$BUILD" 2>/dev/null && find . -path ./external -prune -o -type f \( -name "*.so" -o -name maDGiCart \) -print0 | sort -z | xargs -0 sha256sum ) 2>/dev/null; }
hashes > "$LOG.before.sha256"

mkdir -p "$BUILD"
apptainer exec --bind "$M:/M2DT" "$SIF" bash -c '
  set -e
  export PATH=/usr/local/cuda/bin:$PATH
  export TMPDIR=/tmp
  cd /M2DT/maDGiCart-CH-cuda-build
  cmake -DMADG_USE_CUDA=On -DCMAKE_CUDA_ARCHITECTURES="70;80;86;89" -DCMAKE_BUILD_TYPE=Release /M2DT/maDGiCart-CH
  cmake --build . -j 12
'
rc=$?
echo "[$(date)] build rc=$rc"
hashes > "$LOG.after.sha256"
echo "solver libraries and executable whose contents changed: $(diff "$LOG.before.sha256" "$LOG.after.sha256" | grep -c '^>')"
diff "$LOG.before.sha256" "$LOG.after.sha256" | grep '^>' | awk '{print "   " $3}'
if [ "$rc" = "0" ]; then
  echo "STATUS: DONE. Next: sbatch $M/check_cuda_build.slurm"
else
  echo "STATUS: ERROR build failed; see above. The previous executable stays in place unless the link step ran."
fi
exit $rc
