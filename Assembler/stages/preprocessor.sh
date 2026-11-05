#!/usr/bin/env bash
# preprocessor.sh

INP={$1:-}
if [[ -z $INP ]]; then 
    exit 1
elif [[ ! -e $INP || ! -f $INP || ! -r $INP ]]; then
    exit 1
fi

remove_Comments() {
    local -n _line=$1
    local regex='#([^/]|/+[^/#])*(/+#|/*$)'
    _line=$( sed -E "s@$regex@@g" <<< "$_line" )
}

STATES=()
cat $INP | while read -r line; do
    if [[ -n line ]]; then # Check that a line is not empty before you continue
        remove_Comments $line
    else
        continue
    fi
done
