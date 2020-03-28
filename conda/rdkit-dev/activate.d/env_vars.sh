#!/usr/bin/env bash

export RDBASE=$HOME/pydev/rdkit
export RDBUILD=${RDBASE}/build
export OLD_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib:${RDBASE}/build/lib:$LD_LIBRARY_PATH

function mktest {
    nproc=${1:-4}
    cd $RDBUILD
    make -j $nproc
    ctest -j $nproc --output-on-failure
}
