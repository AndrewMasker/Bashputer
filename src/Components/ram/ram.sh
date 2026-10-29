#!/usr/bin/env bash
# ram.sh

COMPONENT_NAME="RAM"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh

declare -A MEM
MEM_VAL=0x00

parse_Load() {
    local addr=$1
    if is_16_Digit_Hex $addr; then
        printf -v 'MEM_VAL' '0x%02X' ${MEM[$addr]:-0}
        echo data $MEM_VAL
    else
        die "address '$addr' has invalid format. Must be '0x%016X'"
    fi
}

parse_Store() {
    local addr=$1 byte=$2
    if is_16_Digit_Hex $addr; then
        if is_2_Digit_Hex $byte; then
            if [[ $byte == 0x00 ]]; then
                if [[ -v MEM[addr] ]]; then
                    unset 'MEM[$addr]'
                fi
            else
                MEM[$addr]=$byte
            fi
        else
            die "byte '$byte' has invalid format. Must be '0x%02X'"
        fi
    else
        die "address '$addr' has invalid format. Must be '0x%016X'"
    fi
}

parse_Input() {
    local type=$1 value=$2
    case $type in
        load) parse_Load "$value" ; echo done ;;
        store) parse_Store $value ; echo done ;;
        *) die "unknown input type" ;;
    esac
}

run_RAM() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

run_RAM