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
    local -n _addr
    mnemonic=${mnemonic^^}
    if [[ ! -v NUM_BYTES[$mnemonic] ]]; then
        printf "unknown mnemonic '%s' in statement '%s'\n" "$mnemonic" "$1" >&2
        exit 2
    fi
    _addr=$(( _addr + ${NUM_BYTES[$mnemonic]} ))
}
do_Label_Replacement() {
    local -n _STATES=$1
    local regex=':(\.*)([A-Za-z_][A-Za-z0-9_]*)[[:space:]]' addr=0 i j key match correct_match local_regex top_addr next_addr
    local ordered
    mapfile -t ordered < <(for k in "${!LABELS[@]}"; do printf '%s %s\n' "${LABELS[$k]}" "$k"; done | LC_ALL=C sort -n)
    for i in ${#STATES[@]}; do
        if [[ ${STATES[i]} =~ $regex ]]; then
            dots=${BASH_REMATCH[1]}
            label=${BASH_REMATCH[2]}
            scope=${#dots}
            if (( scope == 0 )); then 
                if [[ -v LABELS[$label] ]]; then
                    _STATES[i]=${_STATES[i]//:"$dots""$label"/"${LABELS[$label]}"}
                    advance_ADDR "$line" addr
                    continue
                else
                    printf "global label '%s' does not match nay defined labels\n" "$label" >&2
                    exit 2
                fi
            fi
            local -A matches
            # Get array of matching labels
            for key in ${!LABELS[@]}; do
                if [[ ! ${key//[^.]/} == $dots ]]; then
                    continue
                fi
                if [[ $key =~ *"$label" ]]; then
                    matches[$key]=${LABELS[$key]}
                fi
            done
            # If that array is empty error out
            if (( ${#matches[@]} == 0 )); then
                printf "label usage '%s%s' does not match andy defined labels\n" "$dots" "$label" >&2
                exit 2
            fi
            for match in ${!matches[@]}; do
                for (( j = 0; j < ${#ordered[@]}; j++ )); do
                local_regex='^([0-9]+)[[:space:]]+'"$match"\$
                    if [[ ${ordered[j]} =~ $local_regex ]]; then
                        top_addr=${BASH_REMATCH[1]}
                        if (( top_addr <= addr )); then
                            if (( j+1 == ${#ordered[@]} )); then
                                correct_match=$match
                                break
                            fi
                            local_regex='^([0-9]+)[[:space:]]+.*'
                            if [[ ${ordered[j+1]} =~ $local_regex ]]; then
                                next_addr=${BASH_REMATCH[1]}
                                if (( next_addr > addr )); then
                                    correct_match=$match
                                    break
                                fi
                            fi
                        fi
                    fi
                done
            done
            if [[ -z $correct_match ]]; then
                printf "label '%s%s' is used outside of its scope\n" "$dots" "$label" >&2
                exit 2
            fi
        fi
        _STATES[i]=${_STATES[i]//:"$dots""$label"/"$correct_match"}
        advance_ADDR "$line" addr
    done
}

# Loop over each line
ADDR=0
ORIGIN=0
declare -A LABELS
SCOPES=()
STATES=()
while read -r line || [[ -n $line ]]; do
    if [[ -n $line ]]; then # Ensure the line is not empty
        if ! do_Assembler_Command "$line"; then
            if ! do_Label_Assignment "$line"; then
                STATES+=("$line")
                advance_ADDR "$line" ADDR
            fi
        fi
    else
        continue
    fi
done < "$INP"

do_Label_Replacement STATES