#!/bin/bash
# Pipeline-compatible CPU runner pinned to the DEV build
# (double-division domain_y/z_end fix on program_options.hpp:44,49).
# Same call signature as run_sim.sh (all args forwarded to maDGiCart).
exec /projects/academic/kreyes3/BNL-M2DT/maDGiCart/run_sim_cpu.sh dev "$@"
