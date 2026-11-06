#!/usr/bin/env bash
# preprocessor.sh

# The preprocessor takes a file containing assembly code, removes all comments,
# and breaks multi-statement lines into multiple, single statement lines.
# It then replaces all substitutions with their value and removes their definitions
# from the file.

shopt -s extglob

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
    local rest=$_line tmp
    local -n _STATES=$2
    while [[ -n $rest ]]; do
        if [[ $rest == *\;* ]]; then
            tmp="${rest%%;*}"
            remove_Surrounding_Whitespace tmp
            _STATES+=("$tmp")
            rest="${rest#*;}"
        else
            remove_Surrounding_Whitespace rest
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
    _STATES=("${_STATES[@]}")
}
is_Def_Statement() {
    local statement=$1
    local -n _name=$2
    local -n _val=$3
    local regex='^def[[:space:]]+([A-Za-z]\w*)[[:space:]]*=(.*)'
    if [[ $statement =~ $regex ]]; then
        _name=${BASH_REMATCH[1]}
        _val=${BASH_REMATCH[2]}
        remove_Surrounding_Whitespace _val
        # printf '%s\n' "$_val" >&2
        if [[ $_val =~ ^\{(.*)\}$ ]]; then 
            _val=${BASH_REMATCH[1]}
        fi
        return 0
    else
        return 1
    fi
}
is_Undef_Statement() {
    local statement=$1
    local -n _name=$2
    local regex='^undef[[:space:]]+([A-Za-z].*)'
    if [[ $statement =~ $regex ]]; then
        _name=${BASH_REMATCH[1]}
        remove_Surrounding_Whitespace _name
        return 0
    else
        return 1
    fi
}
replace_Subs() {
    local -n _statement=$1
    local regex='\$([A-Za-z]\w*)\b' subs=()
    local rest=$_statement
    while [[ $rest =~ $regex ]]; do
        subs+=(${BASH_REMATCH[1]})
        rest=${rest#*"${BASH_REMATCH[0]}"}
    done
    for sub in ${subs[@]}; do
        if [[ -v SUBS[$sub] ]]; then
            _statement=${_statement/"\$$sub"/"${SUBS[$sub]}"}
        else
            printf "Unknown substitution name '%s'\n" "$sub" >&2
            exit 2
        fi
    done
}

# Loop over each line, remove comments and surrounding whitespace, then break each line on semiolons
STATES=()
while read -r line || [[ -n $line ]]; do
    remove_Comments line
    remove_Surrounding_Whitespace line
    if [[ -n $line ]]; then # Check that the comment free line is not empty
        break_On_Semicolons line STATES
    else
        continue
    fi
done < "$INP"
remove_Empty_Elements STATES

# Find multiline arithmetic statements and group them into a single comma separated parenthesis group on the same line
n="${#STATES[@]}"
for (( i = 0; i < n; i++)); do
    statement="${STATES[i]}"
    j=$i
    if [[ $statement =~ \( ]]; then 
        opens=${statement//[^\(]/}
        closes=${statement//[^\)]/}
        depth=$(( ${#opens} - ${#closes} ))
        while (( depth > 0 )); do
            (( ++j ))
            if (( j >= n )); then
                printf "no closing parenthesis for statement '%s'\n" "${STATES[i]}" >&2
                exit 2
            fi
            statement+=", ${STATES[j]}"
            unset 'STATES[j]'
            opens=${statement//[^\(]/}
            closes=${statement//[^\)]/}
            depth=$(( ${#opens} - ${#closes} ))
        done
        statement=${statement//\(,/\(}
        statement=${statement//, \)/\)}
        STATES[i]=$statement
        i=$j
    fi
done
STATES=("${STATES[@]}")

# Find multiline def statements and group them into a single colon separated brace group on the same line
n="${#STATES[@]}"
for (( i = 0; i < n; i++)); do
    statement="${STATES[i]}"
    j=$i
    if [[ $statement =~ ^def[[:space:]]+.*=$ ]] && (( j + 1 < n )) && [[ ${STATES[j+1]} == \{* ]]; then
        (( ++j ))
        statement+=" ${STATES[j]}"
        unset 'STATES[j]'
    fi
    if [[ $statement =~ \{ ]]; then 
        while [[ ! $statement =~ \} ]]; do
            (( ++j ))
            if (( j >= n )); then
                printf "no closing brace for statement '%s'\n" "${STATES[i]}" >&2
                exit 2
            fi
            statement+="; ${STATES[j]}"
            unset 'STATES[j]'
        done
        STATES[i]=$statement
        i=$j
    fi
done
STATES=("${STATES[@]}")

# Walk through the STATES and substitute references with their values
declare -A SUBS
for statement in "${STATES[@]}"; do
    name=""
    val=""
    if is_Def_Statement "$statement" name val; then
        replace_Subs val
        SUBS[$name]=$val
    elif is_Undef_Statement "$statement" name; then
        if [[ -v SUBS[$name] ]]; then
            unset SUBS[$name]
        else
            printf "Cannot unset substitution '%s' before it is defined\n" "$name" >&2
            exit 2
        fi
    else
        replace_Subs statement
        SUBSTATES=()
        break_On_Semicolons statement SUBSTATES
        for substate in "${SUBSTATES[@]}"; do
            if [[ -n $substate ]]; then
                echo "$substate"
            fi
        done
    fi
done