#!/bin/bash
#
# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Load a bitstream to a Xilinx FPGA using Vivado in tcl mode.
# Run from the project root directory.

if [[ -z "${ROOT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    export ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
fi

mapfile -t bitstream_files < <(find "${ROOT_DIR}/results" -name "*.bit")

if [[ ${#bitstream_files[@]} -ne 1 ]]; then
    echo "ERROR: Expected exactly one bitstream in results, found ${#bitstream_files[@]}" >&2
    exit 1
fi

vivado -mode tcl -source "${ROOT_DIR}/fpga/scripts/program_fpga.tcl" -tclargs "${bitstream_files[0]}"
