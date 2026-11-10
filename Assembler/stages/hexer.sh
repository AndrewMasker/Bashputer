#!/usr/bin/env bash
# hexer.sh

# The hexer goes through and replaces all values with their bytes and then packages them
# into a form that the loader and rom loader can read.

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../opcodes.sh

set -o posix

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
parse_Number() {
    local arg=$1
    local -n _num=$2
    local hex_regex='^(-?)0[xX]([[:xdigit:]]+)$'
    local bin_regex='^(-?)0[bB]([01]+)$'
    local oct_regex='^(-?)0([0-9]+)$'
    local dec_regex='^(-?)([0-9]+)$'
    if [[ $arg =~ $hex_regex ]]; then
        _num=$(( ${BASH_REMATCH[1]}16#${BASH_REMATCH[2]}))
    elif [[ $arg =~ $bin_regex ]]; then
        _num=$(( ${BASH_REMATCH[1]}2#${BASH_REMATCH[2]}))
    elif [[ $arg =~ $oct_regex ]]; then
        _num=$(( ${BASH_REMATCH[1]}8#${BASH_REMATCH[2]}))
        if [[ ${BASH_REMATCH[2]} =~ '[89]' ]]; then
            printf "octal number '%s' cannot contain 8 or 9\n" "$arg" >&2
            exit 2
        fi
    elif [[ $arg =~ $dec_regex ]]; then
        _num=$(( ${BASH_REMATCH[1]}10#${BASH_REMATCH[2]}))
    else
        return 1
    fi
}
translate_Pseudo_Mnemonic() {
    local mnemonic=$1 args=$2 ARGS=() arg byte val
    local -n __BYTES=$3
    if [[ $mnemonic == DB ]]; then
        break_On_Commas args ARGS
        for arg in "${ARGS[@]}"; do
            if ! parse_Number "$arg" val; then
                printf "db item '%s' is not a number\n" "$arg" >&2
                exit 2
            fi
            printf -v byte '0x%02X' $(( val & 0xFF ))
            __BYTES+=("$byte")
        done
        return 0
    else
        return 1
    fi

}
translate_Line() {
    local line=$1 mnemonic opcode num_args num_bytes args ARGS=() arg byte i j val
    local -n _BYTES=$2
    local regex='^([A-Za-z_][[:alnum:]_]*)'
    local reg_regex='^[rR]([0-9]+)$'
    if [[ ! $line =~ $regex ]]; then
        printf "line '%s' does not start with a mnemonic'\n" "$line" >&2
        exit 2
    fi
    mnemonic=${BASH_REMATCH[1]}
    args=${line#"$mnemonic"}
    read -r args <<< "$args"
    mnemonic=${mnemonic^^}
    if translate_Pseudo_Mnemonic "$mnemonic" "$args" _BYTES; then
        return 0
    fi
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
        elif parse_Number "$arg" val; then
            :
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