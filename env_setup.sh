#!/bin/bash

export WORKSPACE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${WORKSPACE}/.venv/bin/activate
export PATH="/home/andrew/software/slang/build/bin:$PATH"
