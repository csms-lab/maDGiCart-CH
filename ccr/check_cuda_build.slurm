#!/bin/bash
#SBATCH --job-name=madg-gpu-check
#SBATCH --cluster=faculty
#SBATCH --partition=kreyes3
#SBATCH --qos=kreyes3
#SBATCH --gres=gpu:nvidia_L40S:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=/projects/academic/kreyes3/BNL-M2DT/maDGiCart/cuda_build_checks/check_%j.out
#SBATCH --error=/projects/academic/kreyes3/BNL-M2DT/maDGiCart/cuda_build_checks/check_%j.out
# Check the GPU (CUDA) build of maDGiCart-CH after build_cuda_app.sh. About one minute on the
# lab's L40S node. Submit from /projects/academic/kreyes3/BNL-M2DT/maDGiCart:
#     sbatch check_cuda_build.slurm
# Reads the result in cuda_build_checks/check_<job>.out. What it shows:
#   - two small cases under rk3ssp run and write their files;
#   - against the build of 2026-06-02 (reference files of job 24719458): byte-identical as long as
#     no commit has changed the explicit integrator's numerics or the default starting noise;
#   - one seed twice is identical, two seeds differ;
#   - a spectral integrator is refused with a FATAL message;
#   - against the CPU build of the same commit under rk3ssp: agreement to the last digit
#     (3e-17 in composition on 2026-09-21). This is the comparison that must keep holding.
set -uo pipefail
M=/projects/academic/kreyes3/BNL-M2DT/maDGiCart
BUILD=$M/maDGiCart-CH-cuda-build
KEEP=$M/maDGiCart-CH-cuda-build.pre-seed-c5f3a6a
V=$M/cpu_gpu_verification_2026.09.21/gpu
RUN=$M/run_sim_gpu.sh
echo "[$(date)] host=$(hostname) job=$SLURM_JOB_ID start"
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
command -v apptainer >/dev/null 2>&1 || module load apptainer 2>/dev/null || true

SLAB="--dimension 3 --bc_x periodic --bc_y periodic --bc_z neumann --m 0.1 --eps2 4.757402e-5 --sigma 42.1328 --converged_rel_tol 0 --time_integrator rk3ssp --time_step_size 1e-7 --use_adaptive_time_step false --final_time 1.0 --max_time_steps 4 --domain_resolution_x 87 --domain_resolution_y 137 --domain_resolution_z 13 --domain_x_end 1.0 --save_every 2 --solution_output_file out"
PLANE="--dimension 2 --m 0.0 --eps2 4.757402e-5 --sigma 42.1328 --converged_rel_tol 0 --time_integrator rk3ssp --time_step_size 1e-7 --use_adaptive_time_step false --final_time 1.0 --max_time_steps 4 --domain_resolution_x 96 --domain_resolution_y 96 --domain_x_end 1.0 --save_every 2 --solution_output_file out"

run_case() {   # run_case <directory> <args...>
  local d=$1; shift
  mkdir -p "$d" && ( cd "$d" && "$RUN" "$@" > run.log 2>&1 ); local rc=$?
  echo "   $(basename $(dirname $d))/$(basename $d): rc=$rc, $(ls $d/*.vts 2>/dev/null | wc -l) vts files, seed line: $(grep -h 'drawn with seed' $d/run.log $d/*.log 2>/dev/null | head -1)"
}

REF=$V/before
V=$M/cuda_build_checks/check_${SLURM_JOB_ID}
if [ -e "$V" ]; then echo "STATUS: ERROR $V exists"; exit 3; fi
mkdir -p "$V"
echo "solver clone at: $(git -C $M/maDGiCart-CH rev-parse --short HEAD)"
echo "build under test: $(ls -l --time-style=long-iso $BUILD/maDGiCart)"
echo "[$(date)] runs with the rebuilt build"
for c in slab plane; do
  if [ $c = slab ]; then A="$SLAB"; else A="$PLANE"; fi
  run_case $V/after_default/$c $A
  run_case $V/after_seed2/$c   $A --initial_condition_seed 2
  run_case $V/after_seed7a/$c  $A --initial_condition_seed 7
  run_case $V/after_seed7b/$c  $A --initial_condition_seed 7
  run_case $V/after_seed8/$c   $A --initial_condition_seed 8
done
echo "[$(date)] a spectral integrator requested from the GPU build"
mkdir -p $V/refusal && ( cd $V/refusal && "$RUN" ${SLAB/rk3ssp/dct_si} > run.log 2>&1 ); echo "   rc=$?, $(ls $V/refusal/*.vts 2>/dev/null | wc -l) vts files; $(grep -h 'FATAL' $V/refusal/run.log | head -1)"

same() {
  local n=0 bad=0
  for f in $1/*.vts; do n=$((n+1)); cmp -s "$f" "$2/$(basename $f)" || bad=$((bad+1)); done
  echo "$n files, $bad differ"
}
echo "[$(date)] comparisons"
for c in slab plane; do
  echo "   $c: build of 2026-06-02 vs rebuilt without the option: $(same $REF/$c $V/after_default/$c)"
  echo "   $c: build of 2026-06-02 vs rebuilt with seed 2:        $(same $REF/$c $V/after_seed2/$c)"
  echo "   $c: seed 7 vs seed 7 again:                            $(same $V/after_seed7a/$c $V/after_seed7b/$c)"
  echo "   $c: seed 7 vs seed 8:                                  $(same $V/after_seed7a/$c $V/after_seed8/$c)"
done
echo "[$(date)] GPU against CPU: the slab case, seed 7, rk3ssp, CPU spectral build on one thread"
mkdir -p $V/cpu_seed7/slab && ( cd $V/cpu_seed7/slab && OMP_NUM_THREADS=1 $M/run_sim_spectral.sh $SLAB --initial_condition_seed 7 > run.log 2>&1 ); echo "   cpu run rc=$?"
echo "   byte comparison: $(same $V/after_seed7a/slab $V/cpu_seed7/slab)"
python3 - "$V" <<'PY'
import glob, os, re, sys
root = sys.argv[1]
def field(path):
    m = re.search(r'Name="c"[^>]*>(.*?)</DataArray>', open(path).read(), re.S)
    return [float(x) for x in m.group(1).split()]
for g in sorted(glob.glob(os.path.join(root, "after_seed7a", "slab", "out*.vts"))):
    c = os.path.join(root, "cpu_seed7", "slab", os.path.basename(g))
    if not os.path.exists(c):
        print(f"   {os.path.basename(g)}: no CPU file"); continue
    a, b = field(g), field(c)
    print(f"   {os.path.basename(g)}: cells {len(a)}, max |GPU - CPU| = {max(abs(x - y) for x, y in zip(a, b)):.3e}")
PY
echo "STATUS: DONE"
