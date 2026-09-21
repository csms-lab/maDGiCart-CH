#!/bin/bash

#echo "Starting madgc-cuda-64.sif with --nv"
#singularity shell --nv --env LC_ALL=C --bind /projects/academic/kreyes3/BNL-M2DT:/M2DT madg-cuda-amd64.sif
#singularity shell --nv --env LC_ALL=C --bind /projects/academic/kreyes3/BNL-M2DT:/M2DT --bind /scratch:/scratch madg-cuda-amd64.sif

#echo "Starting madgc-cuda-64.sif without --nv"
#singularity shell --env LC_ALL=C --bind /projects/academic/kreyes3/BNL-M2DT:/M2DT madg-cuda-amd64.sif

echo "Starting madgc-gcc-amd-64.sif"
singularity shell --env LC_ALL=C --bind /projects/academic/kreyes3/BNL-M2DT/maDGiCart/maDGiCart-CH-gcc-build:/maDGiCart --bind /projects/academic/kreyes3/BNL-M2DT:/M2DT --bind /scratch:/scratch /projects/academic/kreyes3/BNL-M2DT/maDGiCart/madg-gcc-amd64.sif
