#!/bin/bash

singularity exec --env LC_ALL=C --bind /projects/academic/kreyes3/BNL-M2DT/maDGiCart/maDGiCart-CH-gcc-build:/maDGiCart --bind /projects/academic/kreyes3/BNL-M2DT:/M2DT --bind /scratch:/scratch /projects/academic/kreyes3/BNL-M2DT/maDGiCart/madg-gcc-amd64.sif /maDGiCart/maDGiCart "$@"
