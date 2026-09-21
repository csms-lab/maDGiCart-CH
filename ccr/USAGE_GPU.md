# maDGiCart-CH — GPU (CUDA / NVIDIA L40S) build and usage on CCR

STATUS: WORKING (verified 2026-06-02 on faculty node cpn-f08-13 / L40S).
Runs on the GPU, writes output, exits 0, and the trajectory matches the CPU
build bit-for-bit (validated against ensemble 2026.03.17.161847 sim0000 params).

## Artifacts (all in /projects/academic/kreyes3/BNL-M2DT/maDGiCart/)
- madg-cuda-sm89.sif                : Apptainer image (CUDA 11.8 devel + boost), build + runtime
- maDGiCart-CH-cuda-build/maDGiCart : the compiled CUDA simulator (sm_89)
- run_sim_gpu.sh                    : GPU run wrapper (the --nv analog of run_sim.sh)
- start_shell_gpu.sh               : interactive shell inside the GPU container
- madg-cuda.def / build_cuda_sif.sh : container build recipe + wrapper
- build_cuda_app.sh                : compile wrapper (cmake+make inside the container)
- maDGiCart-CH-cuda-build.cuda11.4-sm70/ : the OLD broken (Volta/CUDA 11.4) build, kept for reference

## RUNNING (must be on an allocated NVIDIA L40S)
GPU jobs run on the lab's faculty node. SLURM directives:

    #SBATCH --cluster=faculty
    #SBATCH --partition=kreyes3
    #SBATCH --qos=kreyes3
    #SBATCH --gres=gpu:nvidia_L40S:1
    #SBATCH --time=...     --mem=...    --cpus-per-task=...

Inside the job, call run_sim_gpu.sh with the usual maDGiCart args (it execs the
binary inside the container with --nv and the tree bound at /M2DT; output .vts
and .log go to the current directory, exactly like the CPU run_sim.sh):

    cd <a writable output dir>
    /projects/academic/kreyes3/BNL-M2DT/maDGiCart/run_sim_gpu.sh \
      --dimension=2 --m=-0.5 --eps2=0.0016 --sigma=35.4308 \
      --domain_x_begin=0 --domain_x_end=6.283185307179586 \
      --domain_resolution_x=128 --domain_resolution_y=128 --domain_resolution_z=1 \
      --time_integrator=rk3ssp --time_step_size=1e-6 --final_time=5

Interactive (on an allocated GPU node):
    ./start_shell_gpu.sh
    # then inside: /M2DT/maDGiCart-CH-cuda-build/maDGiCart <args>

## ENSEMBLE INTEGRATION
The ensemble submit scripts use SIM_EXE=run_sim.sh (CPU). To run on GPU, set
SIM_EXE=run_sim_gpu.sh and add the faculty/L40S #SBATCH directives above to the
submission template. The faculty node has one L40S pair, so GPU ensembles run
with far less concurrency than the public CPU cluster -- best when the per-sim
GPU speedup (especially 3D) outweighs the reduced parallelism.

## HOW IT WAS BUILT (to reproduce / rebuild)
The upstream repo's GPU path is Docker-only (no Docker on CCR) and targets
sm_70 / CUDA 11.4 (predates the L40S = sm_89, Ada). The working CCR recipe:

1) CONTAINER (custom CUDA-devel + boost, built with Apptainer; see madg-cuda.def):
   Build on the COMPILE SERVER with a NODE-LOCAL build scratch:
     ssh compile
     export APPTAINER_TMPDIR=/scratch/<unique-dir>        # NOT /projects (NFS xattrs break the build)
     export APPTAINER_CACHEDIR=/projects/academic/kreyes3/Environments/apptainer_cache
     apptainer build --fakeroot --ignore-fakeroot-command madg-cuda-sm89.sif madg-cuda.def
   Key gotchas (all handled in the def / build_cuda_sif.sh):
     - --ignore-fakeroot-command : skip apptainer's injected faked (needs a newer GLIBC than ubuntu20.04)
     - %post sets  APT::Sandbox::User "root"  : user is not in /etc/subuid, so apt can't drop privileges
     - base = nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu20.04 ; pip-installs cmake<4 (focal cmake 3.16 is too old)

2) SOURCE PATCHES (vs upstream; *.orig backups kept):
   - CMakeLists.txt              : removed hardcoded -arch=sm_70 (use -DCMAKE_CUDA_ARCHITECTURES=89)
   - external/ExternalPetsc.cmake: --with-cuda-arch 70 -> 89 ; pinned PETSc GIT_TAG main -> v3.21.5 ;
                                   removed --download-kokkos* (code uses RAJA not Kokkos; modern Kokkos
                                   needs C++20 which CUDA 11.8 nvcc cannot compile)
   - maDGiCart_main.cpp          : std::quick_exit(0) after run() -- the CUDA MemoryManager singletons
                                   corrupt the host heap during static destruction at exit. Results are
                                   fully written before then and are bit-for-bit correct (compute-sanitizer
                                   reports 0 device errors), so the simulator exits cleanly with results intact.

3) COMPILE (inside the container, on the compile server -- needs internet for the PETSc/RAJA downloads):
     bash build_cuda_app.sh
   i.e. apptainer exec -B <maDGiCart>:/M2DT madg-cuda-sm89.sif bash -c \
        'cd /M2DT/maDGiCart-CH-cuda-build && \
         cmake -DMADG_USE_CUDA=On -DCMAKE_CUDA_ARCHITECTURES=89 -DCMAKE_BUILD_TYPE=Release /M2DT/maDGiCart-CH && \
         cmake --build . -j 12'

## KNOWN NOTES
- unit_testing: 2 CahnHilliardRegression tests fail against STALE hardcoded
  references (they match neither current CPU nor GPU output -- a pre-existing
  test-maintenance issue, not a GPU bug). unit_testing's own gtest main still
  aborts at teardown (only the simulator main was patched). The SIMULATOR exits 0.
- The binary embeds /M2DT paths (built with that bind), so run_sim_gpu.sh binds
  the maDGiCart tree at /M2DT. Do not move the build dir without rebuilding.

## REBUILT 2026-09-21 from solver master 0cd3ec2 (added by the BANJO session of that date)
The CUDA build now comes from the same commit as the CPU spectral build. It knows
`--initial_condition_seed`. It does not contain the spectral integrators `fft_si` and `dct_si`:
the solver's build files leave them out of any GPU build (they transform on the host with FFTW3),
and a run that asks for one stops with a FATAL message. FFTW3 is no longer needed to configure
a GPU build, so this container needs no change.

Checked on cpn-f08-13 (L40S), job 24719525, record in `cpu_gpu_verification_2026.09.21/`:
output byte-identical to the build of 2026-06-02 on two small cases without the seed option and
with seed 2; one seed twice identical; different seeds differ; `dct_si` refused; against the CPU
build under `rk3ssp` the fields agree to 3e-17.

How to rebuild, and three things that went wrong on the way:
- Build on the COMPILE SERVER (compile2, where the June build was made), not on the GPU node.
  The solver compiles its host code with `-march=native`, so a build made on cpn-f08-13 targets
  that node's Intel processor. Such a build was made (job 24719475) and works on that node; it
  was set aside as `maDGiCart-CH-cuda-build.built-on-cpn-f08-13-2026.09.21`.
- Reconfiguring re-runs PETSc's configure step, which needs a usable TMPDIR inside the
  container: `export TMPDIR=/tmp` in the container, or bind /scratch when inside a SLURM job.
- Do NOT build in a `cp -r` copy of a build directory. The copy gives every object file a new
  timestamp, make then skips sources that changed earlier, and the result mixes old and new
  libraries (runs abort with std::bad_alloc; job 24719516). If a copy must be used, remove the
  solver's own object files first (everything outside `external/`), as
  `cpu_gpu_verification_2026.09.21/rebuild_cuda_on_compile_b.sh` does.
- `maDGiCart-CH-cuda-build.pre-seed-c5f3a6a` is a verified copy of the June build directory,
  kept so that the old and new builds can be compared. Removing either kept directory is for a
  person to decide.
