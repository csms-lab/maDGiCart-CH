# ccr/ — building and running maDGiCart-CH on UB CCR

These files build and run the solver on the University at Buffalo's CCR cluster for the CSMS
lab. They were loose files in `/projects/academic/kreyes3/BNL-M2DT/maDGiCart/` until
2026-09-21 and are kept here so that GitHub, CCR and every other clone hold the same ones.
On CCR that directory holds symbolic links to this one; `install_links.sh` makes them.

| File | What it is |
| --- | --- |
| `run_sim_spectral.sh` | Runs the CPU build, which holds every time integrator, inside `madg-gcc-fftw.sif`. The ensemble builder's default. |
| `run_sim_gpu.sh` | Runs the GPU (CUDA) build inside `madg-cuda-sm89.sif` on a node with an NVIDIA GPU. It holds every integrator except the spectral ones. |
| `run_sim_prod.sh`, `run_sim_dev.sh`, `run_sim_cpu.sh`, `run_sim.sh` | Wrappers of older classical CPU builds, which know neither the spectral integrators nor `--initial_condition_seed`. Kept because earlier run records name them. |
| `build_cuda_app.sh` | Rebuilds the GPU build. Run it on the compile server only; it refuses elsewhere. |
| `check_cuda_build.slurm` | One-minute check of the GPU build on the lab's L40S node. |
| `build_spectral.sh` | Rebuilds the CPU build from the worktree `maDGiCart-CH-spectral`. |
| `build_cpu_variant.sh` | Built the older classical CPU builds. |
| `madg-cuda.def`, `build_cuda_sif.sh` | Recipe and build wrapper of the GPU container image. |
| `madg-gcc.def`, `build_gcc_fftw_sif.sh` | Recipe and build wrapper of the CPU container image with FFTW3. |
| `start_shell.sh`, `start_shell_gpu.sh`, `singularity_set_tmp_dir.sh` | Interactive shells inside the containers, and the temporary-directory setting for `apptainer pull`. |
| `USAGE_GPU.md` | How the GPU container and build were first made, and the rules for rebuilding. |

The step-by-step build instructions of record are on the program's context page, section
"Building the solver on CCR". The container images (`.sif`) and the build directories are
not in the repository: they are several GB and are rebuilt from the recipes here.
