#!/bin/bash
#
# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# This script runs simulations outside Vivado, making them faster.
# For usage details run the script with no arguments.
# For more information see: AMD Xilinx UG 900:
# https://docs.xilinx.com/r/en-US/ug900-vivado-logic-simulation/Simulating-in-Batch-or-Scripted-Mode-in-Vivado-Simulator
# To work properly, a git repository in the project directory is required.
# Run from the project root directory.

if [[ -z "${ROOT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    export ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
fi

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

function usage {
    echo "usage: $(basename "$0") [options]"
    echo "  options:"
    echo "    -l         list available tests"
    echo "    -t <test>  run the specified <test>"
    echo "    -g         show gui (use with -t)"
    echo "    -a         run all available tests (does not work with gui)"
    exit 1
}

function print_available_tests {
    find . -mindepth 1 -maxdepth 1 -type d ! -name 'build' ! -name 'common' \
        -printf '%f\n' | sort
}

function list_available_tests {
    print_available_tests
    exit 0
}

function execute_test {
    local test_name=$1
    local prj_file="${ROOT_DIR}/sim/${test_name}/${test_name}.prj"
    local compile_glbl=()
    local xelab_opts=()

    # Remove ignored generated products, but keep untracked source/test files.
    git clean -fdX .

    mkdir -p build
    cd build || exit 1

    if [[ ! -f "${prj_file}" ]]; then
        echo "ERROR: Project file not found: ${prj_file}" >&2
        cd .. || exit 1
        return 1
    fi

    if grep -q 'glbl.v' "${prj_file}"; then
        compile_glbl=(work.glbl)
    fi

    xelab_opts=(
        "work.${test_name}_tb"
        "${compile_glbl[@]}"
        -snapshot "${test_name}_tb"
        -prj "${prj_file}"
        -timescale 1ns/1ps
        -L unisims_ver
    )

    if [[ ${show_gui} ]]; then
        xelab "${xelab_opts[@]}" -debug typical
        xsim "${test_name}_tb" -gui -t "${ROOT_DIR}/tools/sim_cmd.tcl"
    else
        xelab "${xelab_opts[@]}" -standalone -runall \
        | grep -ie '^\|fatal:\|error:\|critical\|warning:' --color=always
    fi

    cd .. || exit 1
}

function run_all {
    local test
    local err_ctr

    while IFS= read -r test; do
        err_ctr=0
        echo -en "${test}:\t"
        err_ctr=$(execute_test "${test}" | grep -oic 'error')
        if [[ ${err_ctr} -eq 0 ]]; then
            echo -e "\033[1;32m PASSED\033[0;39m"
        else
            echo -e "\033[1;31m FAILED\033[0;39m"
        fi
    done < <(print_available_tests)
    exit 0
}

# ------------------------------------------------------------------------------
# Arguments parsing and checking
# ------------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
    usage
fi

cd "${ROOT_DIR}/sim" || exit 1

while getopts aglrs:t: option; do
    case ${option} in
        g) show_gui=1;;
        l) list_available_tests;;
        t) test_name=${OPTARG};;
        a) run_all;;
        *) usage;;
    esac
done

if [[ ${test_name} ]]; then
    execute_test "${test_name}"
fi
