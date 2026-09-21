#!/bin/bash
# Interactive shell inside the GPU container (run on an allocated L40S node).
exec apptainer shell --nv --env LC_ALL=C \
  --bind /projects/academic/kreyes3/BNL-M2DT/maDGiCart:/M2DT \
  --bind /scratch:/scratch \
  /projects/academic/kreyes3/BNL-M2DT/maDGiCart/madg-cuda-sm89.sif
