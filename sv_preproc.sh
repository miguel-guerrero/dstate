#!/bin/bash

if [ "$1" == "" ] || [ "$2" == "" ]; then
    echo "Preprocess a SystemVerilog file"
    echo "Usage: $0 src dst"
    exit 1
fi
src=$1
dst=$2
shift 
shift

vpp=$(which vppreproc 2> /dev/null)
ivl=$(which iverilog 2> /dev/null)

if [ -f "$src" ]; then
    if [ -x "$vpp" ]; then
        $vpp $* $src --simple > $dst
    elif [ -x "$ivl" ]; then
        $ivl $* -E $src -o $dst
    else
        echo "ERROR: No preprocessor found in path (checked for vppreproc and iverilog)"
        echo "please install one of them and make sure they are available in the path"
        exit 1
    fi
    if [ $? != 0 ]; then
        echo "# Error pre-processing $src, skipping it"
        exit 1
    fi
else
    echo "# Warning: skipping $src, not found"
    exit 1
fi
