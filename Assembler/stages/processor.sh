#!/usr/bin/env bash
# processor.sh

# The processor replaces all labels with their value and then
# evaluates expressions within () with bash arithmetic and prints the result

shopt -s extglob

INP=${1:-}
if [[ -z $INP ]]; then 
    exit 1
elif [[ ! -e $INP || ! -f $INP || ! -r $INP ]]; then
    exit 1
fi