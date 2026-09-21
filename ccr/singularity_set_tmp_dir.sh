#!/bin/bash -l
#SBATCH --time=1:00:00
#SBATCH --nodes=8
#SBATCH --partition=general-compute
#SBATCH --qos=general-compute
#SBATCH --cluster=ub-hpc
#SBATCH --constraint=V100|A100|P100

export SINGULARITY_LOCALCACHEDIR=/projects/academic/kreyes3/tmp
export SINGULARITY_CACHEDIR=/projects/academic/kreyes3/tmp
export SINGULARITY_TMPDIR=/projects/academic/kreyes3/tmp
export APPTAINER_LOCALCACHEDIR=/projects/academic/kreyes3/tmp
export APPTAINER_CACHEDIR=/projects/academic/kreyes3/tmp
export APPTAINER_TMPDIR=/projects/academic/kreyes3/tmp
