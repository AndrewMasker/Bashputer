#!/usr/bin/env bash
# preprocessor.sh

# The preprocessor takes a file containing assembly code, removes all comments,
# and breaks multi-statement lines into multiple, single statement lines.
# It then replaces all substitutions with their value and removes their definitions
# from the file.

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
remove_Surrounding_Whitespace() {
    local -n _line=$1
    _line="${_line##*([[:space:]])}"
    _line="${_line%%*([[:space:]])}"
}
break_On_Semicolons() {
    local -n _line=$1
    local rest=$_line
    local -n _STATES=$2
    while [[ -n $rest ]]; do
        if [[ $_line == *\;* ]]; then
            _STATES+=("${rest%%;*}")
            rest="${rest#*;}"
        else
            _STATES+=("$rest")
            rest=""
        fi
    done
}
remove_Empty_Elements() {
    local -n _STATES=$1
    local i
    for i in ${!_STATES[@]}; do
        if [[ -z ${_STATES[i]} ]]; then
            unset _STATES[$i]
        fi
    done
}
is_Def_Statement() {
    local statement=$1
    local -n _name=$2
    local -n _var=$3
    local regex='def[[:space:]]*([A-Za-z]w*)[[:space:]]*=[[:space:]]*(.*)'
    if [[ $statement =~ $regex ]]; then
        _name=${BASH_REMATCH[1]}
        _var=${BASH_REMATCH[2]}
        return 0
    else
        return 1
    fi
}
is_Undef_Statement() {
    local statement=$1
    local -n _name=$2
    local regex='undef[[:space:]]*([A-Za-z]w*)'
    if [[ $statement =~ $regex ]]; then
        _name=${BASH_REMATCH[1]}
        return 0
    else
        return 1
    fi
}

STATES=()
while read -r line || [-n $line]; do
    remove_Comments line
    remove_Surrounding_Whitespace line
    if [[ -n $line ]]; then # Check that the comment free line is not empty
        break_On_Semicolons line STATES
    else
        continue
    fi
done < "$INP"
remove_Empty_Elements STATES

declare -A SUBS
for statement in ${STATES[@]}; do
    name=""
    var=""
    if is_Def_Statement $statement name var; then
        SUBS[$name]=$var
    elif is_Undef_Statement $statement name; then
        if [[ -n ${SUBS[$name]} ]]; then
            unset SUBS[$name]
        else
            return 2
        fi
    fi
done