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

do_Assembler_Command() {
    local line=$1
    if [[ ! $line == '!'* ]]; then return 1; fi
    local lo_regex='^!LABEL_ORIGIN([[:space:]]|$)'
    if [[ $line =~ $lo_regex ]]; then
        ADDR=0
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
        printf "label '%s%s' is at scope %d but scope %d does not exists\n" "$dots" "$label" "$scope" $(( scope - 1 )) >&2 
        exit 2
    fi
    SCOPES=("${SCOPES[@]:0:scope}" "$label")
    label=$(IFS=.; printf '%s' "${SCOPES[*]}")
    if [[ -n ${LABELS[$label]} ]]; then
        printf "label '%s' was defined more than once at address '%s' and at address '%s'\n" "$label" "${LABELS[$label]}" "$ADDR" >&2
        exit 2
    fi
    LABELS[$label]=$ADDR
}
advance_ADDR() {
    local mnemonic=${1%%[[:space:]]*}
    mnemonic=${mnemonic^^}
    if [[ -v ${NUM_BYTES[$mnemonic]} ]]; then
        printf "unknown mnemonic '%s' in statement '%s'\n" "$mnemonic" "$1" >&2
        exit 2
    fi
    ADDR=$(( ADDR + ${NUM_BYTES[$mnemonic]} ))
}

# Loop over each line
ADDR=0
declare -A LABELS
SCOPES=()
STATES=()
while read -r line || [[ -n $line ]]; do
    if [[ -n $line ]]; then # Ensure the line is not empty
        if ! do_Assembler_Command $line; then
            if ! do_Label_Assignment $line; then
                STATES+=("$line")
                advance_ADDR $line
            fi
        fi
    else
        continue
    fi
done < "$INP"