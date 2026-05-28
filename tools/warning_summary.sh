#!/bin/bash
#
# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# This script extracts warnings and errors from the synthesis
# and implementation logs to a single log file.
# Run from the project root directory.

if [[ -z "${ROOT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    export ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
fi

PROJECT_PATH="${ROOT_DIR}/fpga/build"
LOG_FILE="${ROOT_DIR}/results/warning_summary.log"

SYNTH_IGNORE='\[Constraints[[:space:]]18-5210\]|\[Netlist[[:space:]]29-345\]'
IMPL_IGNORE='replace_with_codes_to_be_ignored_only_when_justified'

mkdir -p "$(dirname "${LOG_FILE}")"

printf '%b\n' 'Warnings, critical warnings and errors from synthesis and implementation\n' > "${LOG_FILE}"
printf '%b\n\n' "Created: $(date '+%F %T')" >> "${LOG_FILE}"

printf '%b\n' '----SYNTHESIS----' >> "${LOG_FILE}"
SYNTH_LOG="${PROJECT_PATH}"/*.runs/synth_1/runme.log
if compgen -G "$SYNTH_LOG" > /dev/null
then
    if ! grep -h -v -E "${SYNTH_IGNORE}" $SYNTH_LOG | grep -h -E 'CRITICAL|WARNING|ERROR' >> "${LOG_FILE}"
    then
        printf 'CLEAR :)\n' >> "${LOG_FILE}"
    fi
else
    printf 'No synthesis log file found!\n' >> "${LOG_FILE}"
fi

printf '%b\n' '\n----IMPLEMENTATION----' >> "${LOG_FILE}"
IMPL_LOG="${PROJECT_PATH}"/*.runs/impl_1/runme.log
if compgen -G "$IMPL_LOG" > /dev/null
then
    if ! grep -h -v -E "${IMPL_IGNORE}" $IMPL_LOG | grep -h -E 'CRITICAL|WARNING|ERROR' >> "${LOG_FILE}"
    then
        printf 'CLEAR :)\n' >> "${LOG_FILE}"
    fi
else
    printf 'No implementation log file found!\n' >> "${LOG_FILE}"
fi

sed -i -r \
    -e "s|/home/([a-zA-Z0-9_]*/)*$(basename "${ROOT_DIR}")/||g" \
    -e "s|[A-Za-z]:[\\/].*[\\/]$(basename "${ROOT_DIR}")[\\/]||g" \
    "${LOG_FILE}"
