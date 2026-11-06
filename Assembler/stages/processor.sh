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
    if [[ ! $line =~ '^!.*' ]]; then return 1; fi
    if [[ $line =~ '!LABEL_ORIGIN[[:space:]]*.*' ]]; then
        ADDR=0
        return 0
    else
        printf "unknown assembler command '%s" "$line" >&2
        exit 2
    fi
}
do_Label_Assignment() {
    local line=$1 dots label scope regex='^(\.*):([A-Za-z]\w*).*'
    if [[ ! $line =~ $regex ]]; then return 1; fi
    dots=${BASH_REMATCH[1]}
    label=${BASH_REMATCH[2]}
    scope=${#dots}
    SCOPES[scope]=$label
    SCOPES=${SCOPES[@]:0:$((scope+1))}
    while (( scope != 0 )); do 
        if [[ -z ${SCOPES[scope-1]} ]]; then
            printf "scope '%s' empty for label '%s%s'" $(( scope - 1 )) "$dots" "$label" >&2
            exit 2
        fi
        label="${SCOPES[scope-1]}"."$label"
        scope=$(( scope - 1 ))
    done
    if [[ -n ${LABELS[$label]} ]]; then
        printf "label '%s' was defined more than once at address '%s' and at address '%s'\n" "$label" "${LABELS[$label]}" "$ADDR" >&2
        exit 2
    fi
    LABELS[$label]=$ADDR
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
            fi
        fi
    else
        continue
    fi
done < "$INP"