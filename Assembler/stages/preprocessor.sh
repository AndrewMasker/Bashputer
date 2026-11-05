#!/usr/bin/env bash
# preprocessor.sh

INP={$1:-}
if [[ -z $INP ]]; then 
    exit 1
elif [[ ! -e $INP || ! -f $INP || ! -r $INP ]]; then
    exit 1
fi

remove_Comments() {
    local -n line=$1
    regex=''
}

STATES=()
cat $INP | while read -r line; do
    if [[ -n line ]]; then # Check that a line is not empty before you continue

    else
        continue
    fi
done
