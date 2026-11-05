#!/usr/bin/env bash
# preprocessor.sh

INP=${1:-}
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
remove_Trailing_Whitespace() {
    local -n _line=$1
    local regex='[[:space:]]+$'
    _line=$( sed -E "s@$regex@@g" <<< "$_line" )
}

STATES=()
while read -r line; do
    remove_Comments line
    remove_Trailing_Whitespace line
    if [[ -n $line ]]; then # Check that the comment free line is not empty
        
    else
        continue
    fi
done < "$INP"
