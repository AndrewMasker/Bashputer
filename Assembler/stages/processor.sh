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

do_Assembler_Command() {
    local line=$1
    if [[ ! $line == '!'* ]]; then return 1; fi
    local lo_regex='^!LABEL_ORIGIN([[:space:]]|$)'
    if [[ $line =~ $lo_regex ]]; then
        ORIGIN=$ADDR
        return 0
    else
        printf "unknown assembler command '%s'\n" "$line" >&2
        exit 2
    fi
}
do_Label_Assignment() {
    local line=$1 dots label scope regex='^(\.*)([A-Za-z_][A-Za-z0-9_]*):$'
    if [[ ! $line =~ $regex ]]; then return 1; fi
    dots=${BASH_REMATCH[1]}
    label=${BASH_REMATCH[2]}
    scope=${#dots}
    if (( scope > ${#SCOPES[@]} )); then
        printf "label '%s%s' is at scope %d but scope %d does not exist\n" "$dots" "$label" "$scope" $(( scope - 1 )) >&2 
        exit 2
    fi
    SCOPES=("${SCOPES[@]:0:scope}" "$label")
    label=$(IFS=.; printf '%s' "${SCOPES[*]}")
    if [[ -n ${LABELS[$label]} ]]; then
        printf "label '%s' was defined more than once at address '%s' and at address '%s'\n" "$label" "${LABELS[$label]}" "$ADDR" >&2
        exit 2
    fi
    LABELS[$label]=$(( ADDR ))
}
advance_ADDR() {
    local mnemonic=${1%%[[:space:]]*}
    local -n _addr=$2
    mnemonic=${mnemonic^^}
    if [[ ! -v NUM_BYTES[$mnemonic] ]]; then
        printf "unknown mnemonic '%s' in statement '%s'\n" "$mnemonic" "$1" >&2
        exit 2
    fi
    _addr=$(( _addr + ${NUM_BYTES[$mnemonic]} ))
}
do_Label_Replacement() {
    local -n _STATES=$1
    local regex=':(\.*)([A-Za-z_][A-Za-z0-9_]*)' i dots label scope label_key local_regex parents
    for i in "${!_STATES[@]}"; do
        while [[ ${_STATES[i]} =~ $regex ]]; do
            dots=${BASH_REMATCH[1]}
            label=${BASH_REMATCH[2]}
            scope=${#dots}
            if (( scope == 0 )); then 
                label_key=$label
            else
                IFS=. read -ra parents <<< "${STATE_SCOPES[i]}"
                if (( scope > ${#parents[@]} )); then
                    printf "label '%s' has a scope of '%s' but only has '%s' parent labels\n" "$label" "$scope" "${#parents[@]}" >&2
                    exit 2
                fi
                label_key=$(IFS=.; printf '%s' "${parents[*]:0:scope}")."$label"
            fi
            if [[ -v LABELS[$label_key] ]]; then
                local_regex="(:${dots//./\\.}$label)([^A-Za-z0-9_]|$)"
                [[ ${_STATES[i]} =~ $local_regex ]] || true
                _STATES[i]=${_STATES[i]/"${BASH_REMATCH[1]}${BASH_REMATCH[2]}"/$((${LABELS[$label_key]} - ${STATE_ORIGINS[i]}))"${BASH_REMATCH[2]}"}
                continue
            else
                printf "label '%s' does not match any defined labels\n" "$label" >&2
                exit 2
            fi
        done
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

do_Label_Replacement STATES