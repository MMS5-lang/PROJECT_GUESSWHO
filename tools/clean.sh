#!/bin/bash
#
# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Remove untracked files from the project
# To work properly, a git repository in the project directory is required.
# Run from the project root directory.

if [[ -z "${ROOT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    export ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
fi

cd "${ROOT_DIR}" || exit 1
git clean -fdX
