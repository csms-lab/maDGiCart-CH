#!/bin/bash
# Run the GPU (CUDA 11.8 / sm_89, NVIDIA L40S) maDGiCart-CH build.
# GPU analog of run_sim.sh. MUST run on a node with an NVIDIA L40S allocated
# (faculty partition: --cluster=faculty --partition=kreyes3 --qos=kreyes3
#  --gres=gpu:nvidia_L40S:1).  --nv injects the host driver into the container.
# The CUDA binary was built with the maDGiCart tree bound at /M2DT, so its
# embedded source/test paths and RPATH resolve only under that bind.
exec apptainer exec --nv --env LC_ALL=C \
  --bind /projects/academic/kreyes3/BNL-M2DT/maDGiCart:/M2DT \
  --bind /scratch:/scratch \
  /projects/academic/kreyes3/BNL-M2DT/maDGiCart/madg-cuda-sm89.sif \
  /M2DT/maDGiCart-CH-cuda-build/maDGiCart "$@"
