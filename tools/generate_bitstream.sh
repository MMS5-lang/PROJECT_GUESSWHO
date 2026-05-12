#!/bin/bash
#
# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# This script runs Vivado in tcl mode and sources an apropriate tcl file to run
# all the steps to generate bitstream. When finished, the bitsream is copied to
# the result directory. Additionally, all the warnings and errors logged during
# synthesis and implementation are also copied to results/warning_summary.log
# To work properly, a git repository in the project directory is required.
# Run from the project root directory.

# Remove ignored Vivado build products without deleting untracked source files.
# On Windows this can fail when Vivado, VS Code, or DVT keeps fpga/build open.
# Continue anyway and let Vivado recreate the project with -force below.
git clean -fdX fpga || echo "WARNING: Could not fully clean fpga/build; continuing."

# Run Vivado and generate bitstream
cd fpga
vivado -mode tcl -source scripts/generate_bitstream.tcl
vivado_status=$?
cd ${ROOT_DIR}

# Copy bitstream to results
if [ ${vivado_status} -eq 0 ]; then
    find fpga/build -name "*.bit" -exec cp {} results/ \;
fi

# Copy warnings and errors to a single log file in results
./tools/warning_summary.sh

exit ${vivado_status}
