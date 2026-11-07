#!/usr/bin/env bash
# hexer.sh

# The hexer goes through and replaces all values with their bytes and then packages them
# into a form that the loader and rom loader can read.

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../opcodes.sh

shopt -s extglob

INP=${1:-}
if [[ -z $INP ]]; then 
    exit 1
elif [[ ! -e $INP || ! -f $INP || ! -r $INP ]]; then
    exit 1
fi

remove_Surrounding_Whitespace() {
    local -n _line=$1
    _line="${_line##*([[:space:]])}"
    _line="${_line%%*([[:space:]])}"
}
break_On_Commas() {
    local -n _line=$1
    local rest=$_line tmp
    local -n _STATES=$2
    while [[ -n $rest ]]; do
        if [[ $rest == *\,* ]]; then
            tmp="${rest%%,*}"
            remove_Surrounding_Whitespace tmp
            _STATES+=("$tmp")
            rest="${rest#*,}"
        else
            remove_Surrounding_Whitespace rest
            _STATES+=("$rest")
            rest=""
        fi
    done
}
translate_Line() {
    local line=$1 mnemonic opcode num_args num_bytes args ARGS=() arg byte i j val
    local -n _BYTES=$2
    local regex='^([A-Za-z_][[:alnum:]_]*)'
    local reg_regex='^[rR]([0-9]+)$'
    local num_regex='^([0-9]+|0[xX][[:xdigit:]]+)$'
    if [[ ! $line =~ $regex ]]; then
        printf "line '%s' does not start with a mnemonic'\n" "$line" >&2
        exit 2
    fi
    mnemonic=${BASH_REMATCH[1]}
    args=${line#"$mnemonic"}
    read -r args <<< "$args"
    mnemonic=${mnemonic^^}
    if [[ ! -v OPCODES[$mnemonic] ]]; then
        printf "mnemonic '%s' does not match any opcodes\n" "$mnemonic" >&2
        exit 2
    fi
    if [[ ! -v NUM_ARGS[$mnemonic] ]]; then
        printf "mnemonic '%s' does not have an associated number of arguments\n" "$mnemonic" >&2
        exit 1
    fi
    if [[ ! -v NUM_BYTES[$mnemonic] ]]; then
        printf "mnemonic '%s' does not have an associated number of bytes\n" "$mnemonic" >&2
        exit 1
    fi
    opcode=${OPCODES[$mnemonic]}
    num_args=${NUM_ARGS[$mnemonic]}
    num_bytes=${NUM_BYTES[$mnemonic]}
    num_bytes=($num_bytes)
    if (( ${#num_bytes[@]} != num_args )); then
        printf "mnemonic '%s' does not specify the same amount of number of bytes as there are arguments\n" "$mnemonic" >&2
        exit 1
    fi
    break_On_Commas args ARGS
    if (( ${#ARGS[@]} != num_args )); then
        printf "line '%s' has the incorrect argument number for opcode '%s'\n" "$line" "$mnemonic" >&2
        exit 2
    fi
    printf -v byte '0x%02X' $opcode
    _BYTES+=("$byte") 
    for i in "${!ARGS[@]}"; do
        arg=${ARGS[i]}
        n_bytes=${num_bytes[i]}
        if [[ $arg =~ $reg_regex ]]; then
            val=${BASH_REMATCH[1]}
        elif [[ $arg =~ $num_regex ]]; then
            val=$(( arg ))
        else
            printf "line '%s' contains an argument '%s' with unknown type\n" "$line" "$arg" >&2
            exit 2
        fi
        for (( j = 0; j < n_bytes; j++)); do
            printf -v byte '0x%02X' $(( val &  0xFF ))
            _BYTES+=("$byte") 
            val=$(( val >> 8 ))
        done
    done
}

BYTES=()
while read -r line || [[ -n $line ]]; do
    if [[ -n $line ]]; then
        translate_Line "$line" BYTES
    fi
done < "$INP" 

num_strung=0
ADDR=0
for byte in "${BYTES[@]}"; do
    if (( num_strung == 0 )); then
        printf '0x%016X' "$ADDR"
    fi
    printf ' %s' "$byte"
    ADDR=$(( ADDR + 1 ))
    num_strung=$(( num_strung + 1 ))
    if (( num_strung == 16 )); then
        printf '\n'
        num_strung=0
    fi
done
if (( num_strung != 0 )); then
    printf '\n'
fi