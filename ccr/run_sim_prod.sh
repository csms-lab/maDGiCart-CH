#!/bin/bash
# Pipeline-compatible CPU runner pinned to the PROD build
# (original, committed integer-division domain sizing). Default --sim-exe for build_ensemble.py.
# Same call signature as run_sim.sh (all args forwarded to maDGiCart).
exec /projects/academic/kreyes3/BNL-M2DT/maDGiCart/run_sim_cpu.sh prod "$@"
