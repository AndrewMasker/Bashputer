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

MACRO_ID=0

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
_replace_Subs__Statement_Into_Subs_And_Arguments() {
    local rest=$_statement
    local regex='\$([A-Za-z]\w*)\b' 
    while [[ $rest =~ $regex ]]; do
        local depth=0
        local sub="${BASH_REMATCH[1]}"
        local argument=""
        rest=${rest#*"\$$sub"}
        if [[ ${rest:0:1} == '[' ]]; then
            depth=1
            argument+='['
            while (( depth != 0 )); do
                if [[ -z $rest ]]; then
                    printf "substitution expansion of statement '%s' has unbalanced brackets\n" "$_statement" >&2
                    exit 2
                fi
                rest=${rest:1}
                if [[ ${rest:0:1} == '[' ]]; then
                    depth=$(( depth + 1))
                elif [[ ${rest:0:1} == ']' ]]; then
                    depth=$(( depth - 1 ))
                fi
                argument+="${rest:0:1}"
            done
        fi
        subs+=("$sub")
        arguments+=("$argument")
    done
}
expand_Subs() {
    local line=$1
    replace_Subs line
    printf '%s' "$line"
}
rename_Body_Labels(){
    local _body=$1 scan=$1 name defs=() name_regex
    local -n _out=$2
    local def_regex='(^|;)[[:space:]]*(\.*[A-Za-z_]\w*):[[:space:]]*(;|$)'
    while [[ $scan =~ $def_regex ]]; do
        defs+=("${BASH_REMATCH[2]}")
        scan=${scan#*"${BASH_REMATCH[2]}"}
    done
    MACRO_ID=$(( MACRO_ID + 1 ))
    for name in "${defs[@]}"; do
        name_regex='((^|;)[[:space:]]*)('"$name"'):'
        while [[ $_body =~ $name_regex ]]; do
            _body=${_body/"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]}${name}_MACROLOCAL_${MACRO_ID}:"}
        done
    done
    for name in "${defs[@]}"; do
        name_regex=':'"$name"'([^A-Za-z0-9_]|$)'
        while [[ $_body =~ $name_regex ]]; do
            _body=${_body/"${BASH_REMATCH[0]}"/":${name}_MACROLOCAL_${MACRO_ID}${BASH_REMATCH[1]}"}
        done
    done
    _out="$_body"
}
_replace_Subs__Replace_Macro_With_Arguments() {
    local regex='^[[:space:]]*([A-Za-z]\w*)[[:space:]]*=(.*)$'
    local rest=$argument
    remove_Surrounding_Whitespace rest
    while [[ $rest =~ $regex ]]; do
        local var="${BASH_REMATCH[1]}"
        local value=""
        rest="${BASH_REMATCH[2]}"
        local depth=0
        while true; do
            if [[ ${rest:0:1} == ',' || $rest == "" ]] && (( depth == 0 )); then
                rest="${rest:1}"
                break
            fi
            if [[ -z $rest ]] && (( depth != 0 )); then
                printf "unbalanced parentheses in %s\n" "$sub" >&2
                exit 2
            fi
            if [[ ${rest:0:1} == '(' ]]; then
                depth=$(( depth + 1 ))
            elif [[ ${rest:0:1} == ')' ]]; then
                depth=$(( depth - 1 ))
            fi
            value+="${rest:0:1}"
            rest="${rest:1}"
        done
        remove_Surrounding_Whitespace value
        local tmp="$value"
        value=$(expand_Subs "$value") || { printf "error expanding argument substitutions for variable '%s' with value '%s'\n" "$var" "$tmp" >&2; exit 2; }
        if [[ ! -v map[$var] ]]; then
            map[$var]="$value"
        else
            printf "variable '%s' defined more than once in call of macro '%s' in statement '%s'\n" "$var" "$sub" "$_statement" >&2
            exit 2
        fi
    done
    if [[ $rest != "" ]]; then
        printf "invalid macro arguments in '%s'\n" "$sub" >&2
        exit 2
    fi
    local body
    rename_Body_Labels "${SUBS[$sub]}" body
    local var_regex='^([^%]*)%([A-Za-z]\w*)(.*)'
    local out=""
    while [[ $body =~ $var_regex ]]; do
        out+="${BASH_REMATCH[1]}"
        local var=${BASH_REMATCH[2]}
        if [[ -v map[$var] ]]; then
            out+="${map[$var]}"
        else
            printf "unknown variable '%s' in macro call '%s' with body '%s'\n" "$var" "$sub" "${SUBS[$sub]}" >&2
            exit 2
        fi
        body=${BASH_REMATCH[3]}
    done
    out+=$body
    _statement=${_statement/"\$$sub[$argument]"/"$out"}
}
replace_Subs() {
    local -n _statement=$1
    local subs=() arguments=()
    _replace_Subs__Statement_Into_Subs_And_Arguments
    local i
    for i in ${!subs[@]}; do
        local sub=${subs[i]}
        local argument=${arguments[i]}
        declare -A map=()
        if [[ -v SUBS[$sub] ]]; then
            if [[ -n $argument ]]; then
                argument="${argument:1:-1}"
                _replace_Subs__Replace_Macro_With_Arguments
            else
                local body
                rename_Body_Labels "${SUBS[$sub]}" body
                _statement=${_statement/"\$$sub"/"$body"}
            fi
        else
            printf "Unknown substitution name '%s'\n" "$sub" >&2
            exit 2
        fi
    done
}
ensure_No_Blacklisted() {
    local state=$1
    if [[ $state =~ '$' ]]; then 
        printf "unexpanded '\$' in statement '%s'\n" "$state" >&2
        exit 2
    fi
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
                ensure_No_Blacklisted "$substate"
                echo "$substate"
            fi
        done
    fi
done