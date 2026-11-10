#!/usr/bin/env bash
# processor.sh

# The processor replaces all labels with their value and then
# evaluates expressions within () with bash arithmetic and prints the result

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../opcodes.sh

shopt -s extglob

INP=${1:-}
if [[ -z $INP ]]; then 
    exit 1
elif [[ ! -e $INP || ! -f $INP || ! -r $INP ]]; then
    exit 1
fi

ANON_ID=0

remove_Surrounding_Whitespace() {
    local -n _line=$1
    _line="${_line##*([[:space:]])}"
    _line="${_line%%*([[:space:]])}"
}
do_Assembler_Command() {
    local line=$1
    if [[ ! $line == '!'* ]]; then return 1; fi
    local cmd=${line%%[[:space:]]*} arg=${line#"${line%%[[:space:]]*}"}
    
    # local label_origin_regex='^!LABEL_ORIGIN([[:space:]]|$)'
    # local scope_push_regex='^!SCOPE[[:space:]]+([[A-Za-z_]\w*])[[:space:]]*(;|$)'
    # local scope_pop_regex='^!ENDSCOPE[[:space:]]*(;|$)'
    case ${cmd^^} in
        !LABEL_ORIGIN)
            ORIGIN=$ADDR
            return 0
            ;;
        !SCOPE)
            remove_Surrounding_Whitespace arg
            if [[ -z $arg ]]; then
                arg="ANON_$ANON_ID"
                ANON_ID=$(( ANON_ID + 1 ))
            fi
            do_Label_Assignment "$arg:"
            SCOPES+=("$arg")
            ;;
        !ENDSCOPE)
            if [[ -z ${SCOPES[0]} ]]; then
                printf "no scope exists to end on line '%s'\n" "$line" >&2
                exit 2
            fi
            unset 'SCOPES[-1]'
            ;;
        *)
            printf "unknown assembler command '%s'\n" "$line" >&2
            exit 2
            ;;
    esac
}
do_Label_Assignment() {
    local line=$1 label regex='^([A-Za-z_][A-Za-z0-9_]*):$'
    if [[ ! $line =~ $regex ]]; then return 1; fi
    if [[ -z ${SCOPES[0]} ]]; then
        label=${BASH_REMATCH[1]}
    else
        label=$(IFS=.; printf '%s' "${SCOPES[*]}")."${BASH_REMATCH[1]}"
    fi
    if [[ -n ${LABELS[$label]} ]]; then
        printf "label '%s' was defined more than once at address '%s' and at address '%s'\n" "$label" "${LABELS[$label]}" "$ADDR" >&2
        exit 2
    fi
    LABELS[$label]=$(( ADDR ))
}
count_Items() {
    local line=$1
    local -n _n=$2
    while [[ $line =~ \([^()]*\) ]]; do line=${line/"${BASH_REMATCH[0]}"/_}; done
    if [[ -z ${line//[[:space:]]/} ]]; then _n=0; return 0; fi
    local commas=${line//[^,]/}
    _n=$(( ${#commas} + 1 ))
}
advance_Pseudo_Mnemonic() {
    local mnemonic=${1%%[[:space:]]*} line=$1
    local -n __addr=$2
    line=${line#"$mnemonic"}
    mnemonic=${mnemonic^^}
    if [[ $mnemonic == DB ]]; then
        local n
        count_Items "$line" n
        __addr=$(( __addr + n ))
        return 0
    else
        return 1
    fi
}
advance_ADDR() {
    local mnemonic=${1%%[[:space:]]*} line=$1 n 
    local -n _addr=$2
    mnemonic=${mnemonic^^}
    if advance_Pseudo_Mnemonic "$line" _addr; then
        return 0
    fi
    if [[ ! -v NUM_BYTES[$mnemonic] ]]; then
        printf "unknown mnemonic '%s' in statement '%s'\n" "$mnemonic" "$1" >&2
        exit 2
    fi
    _addr=$(( _addr + 1 ))
    for n in ${NUM_BYTES[$mnemonic]}; do _addr=$(( _addr + n )); done
}
do_Label_Replacement() {
    local -n _STATES=$1
    local regex=':(\.?)([A-Za-z_]\w*(\.[A-Za-z_]\w*)*)([^A-Za-z0-9_]|$)' i dot label label_key local_regex parents resolved
    for i in "${!_STATES[@]}"; do
        while [[ ${_STATES[i]} =~ $regex ]]; do
            dot=${BASH_REMATCH[1]}
            label=${BASH_REMATCH[2]}
            if [[ $dot == "" ]]; then # Global label or pathed from global
                label_key=$label
                if [[ ! -v LABELS[$label_key] ]]; then
                    printf "label '%s' in statement '%s' could not be resolved\n" "$dot$label" "${_STATES[i]}" >&2
                    exit 2
                fi
            else
                IFS=. read -ra parents <<< "${STATE_SCOPES[i]}"
                resolved=false
                while [[ -n $parents ]]; do
                    label_key=$(IFS=".";echo "${parents[*]}")".$label"
                    if [[ -v LABELS[$label_key] ]]; then
                        resolved=true
                        break
                    fi
                    unset 'parents[-1]'
                done    
                if ! resolved; then
                    label_key=$label
                    if [[ -v LABELS[$label_key] ]]; then
                        resolved=true
                    fi
                fi
                if ! $resolved; then
                    printf "label '%s' in statement '%s' could not be resolved\n" "$dot$label" "${_STATES[i]}" >&2
                    exit 2
                fi
            fi
            _STATES[i]=${_STATES[i]/"${BASH_REMATCH[0]}"/$((${LABELS[$label_key]} - ${STATE_ORIGINS[i]}))"${BASH_REMATCH[4]}"}
        done
    done
}
check_Arithmetic() {
    local expr=$1
    local bad_chars='([^-[:alnum:][:blank:]_+*/%<>=!&|^~?,()#@:])'
    if [[ $expr =~ $bad_chars ]]; then
        printf "Expression '%s' may not contain the character '%s'\n" "$expr" "${BASH_REMATCH[1]}" >&2
        exit 2
    fi
}
replace_Binary() {
    local -n _expr=$1
    local regex='(^|[^[:alnum:]_])0[bB]([01]+)'
    while [[ $_expr =~ $regex ]]; do
        _expr=${_expr/"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]}2#${BASH_REMATCH[2]}"}
    done
}
do_Arithmetic() {
    local -n _STATES=$1
    local working group expr result i depth
    for i in "${!_STATES[@]}"; do
        while [[ ${_STATES[i]} =~ \( ]]; do
            working="${_STATES[i]#*\(}"
            group=\(
            depth=1
            while (( depth != 0 )); do
                if [[ -z $working ]]; then
                    printf "arithmetic group '%s' has unbalanced parentheses\n" "$group" >&2
                    exit 2
                fi
                if [[ ${working:0:1} == \( ]]; then
                    depth=$(( depth + 1 ))
                elif [[ ${working:0:1} == \) ]]; then
                    depth=$(( depth - 1))
                fi
                group+=${working:0:1}
                working=${working:1}
            done
            expr=${group:1:-1}
            if [[ -z $expr ]]; then
                printf "Empty arithmetic expression in partially evaluated statement '%s'\n" "${_STATES[i]}" >&2
                exit 2
            fi
            check_Arithmetic "$expr"
            replace_Binary expr
            result=$( env -i "$BASH" --norc --noprofile -c 'set -u; printf "%d" "$(( $1 ))"' _ "$expr") || {
                printf "Could not evaluate arithmetic expression '%s'\n" "$expr" >&2; exit 2
            }
            _STATES[i]=${_STATES[i]/"$group"/" $result "}
        done
        if [[ ${_STATES[i]} =~ \) ]]; then
            printf "arithmetic group in partially evaluated statement '%s' has unbalanced parentheses\n" "${_STATES[i]}" >&2
            exit 2
        fi
    done
}

# Loop over each line
ADDR=0
ORIGIN=0
declare -A LABELS
SCOPES=()
STATES=()
STATE_SCOPES=()
STATE_ORIGINS=()
while read -r line || [[ -n $line ]]; do
    if [[ -n $line ]]; then # Ensure the line is not empty
        if ! do_Assembler_Command "$line"; then
            if ! do_Label_Assignment "$line"; then
                STATES+=("$line")
                STATE_SCOPES+=("$(IFS=.; printf '%s' "${SCOPES[*]}")")
                STATE_ORIGINS+=("$ORIGIN")
                advance_ADDR "$line" ADDR
            fi
        fi
    else
        continue
    fi
done < "$INP"

if [[ -n ${SCOPES[0]} ]]; then
    printf "unclosed scopes '%s'\n" "${SCOPES[*]}" >&2
    exit 2
fi

do_Label_Replacement STATES
do_Arithmetic STATES

for statement in "${STATES[@]}"; do
    echo "$statement"
done