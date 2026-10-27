#!/usr/bin/env bash
# bus_interconnect.sh

COMPONENT_NAME="Bus Interconnect"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh
source "$MY_DIR"/config.sh

NAME=none
PERM=RW
printf -v 'ADDR' '0x%016X' 0

get_Bus() {
    local addr=$1 i
    NAME=none
    PERM=RW
    printf -v 'ADDR' '0x%016X' $(( addr ))
    for i in "${!ADDR_LOW[@]}"; do 
        if (( ( ADDR_LOW[i] <= addr ) && ( addr < ADDR_HIGH[i] ) )); then
            NAME="${NAMES[i]}"
            PERM="${PERMISSIONS[i]}"
            printf -v 'ADDR' '0x%016X' $(( addr - ADDR_LOW[i] ))
            return 0
        fi
    done
}

parse_Load() {
    local addr=$1
    if is_16_Digit_Hex $addr; then
        get_Bus $addr
        if [[ $PERM == *R* ]]; then
            echo "$NAME load $ADDR"
        else
            echo "data $DENIED_READ_DATA"
        fi
    else
        die "incorrect address format of '$addr'. Must be '0x%016X' formatted"
    fi
}

parse_Store() {
    local addr=$1 byte=$2
    if is_16_Digit_Hex $addr; then
        if is_2_Digit_Hex $byte; then
            get_Bus $addr
            if [[ $PERM == *W* ]]; then
                echo "$NAME store $ADDR $byte"
            else
                return 0
            fi
        else
            die "incorrect byte format of '$byte'. Must be '0x%02X' formatted"
    else
        die "incorrect address format of '$addr'. Must be '0x%016X' formatted"
    fi
}

parse_Data() {
    local byte=$1
    if is_2_Digit_Hex $byte; then
        echo "data $byte"
    else
        die "incorrect byte format of '$byte'. Must be '0x%02X' formatted"
    fi
}

parse_Input() {
    local type=$1 value=$2
    case $type in
        load) parse_Load "$value" ; echo done ;;
        store) parse_Store $value ; echo done ;;
        data) parse_Data "$value" ; echo done
        *) die "unknown input type" ;;
    esac
}

run_BUS_INTERCONNECT() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

run_BUS_INTERCONNECT