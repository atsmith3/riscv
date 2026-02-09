#!/bin/bash

export WORKSPACE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${WORKSPACE}/.venv/bin/activate
export PATH="/home/andrew/software/slang/build/bin:$PATH"

export VIVADO_ROOT="/home/andrew/software/vivado"
export VIVADO_VERSION="2025.2"
export PATH="$VIVADO_ROOT/$VIVADO_VERSION/Vivado/bin:$PATH"
