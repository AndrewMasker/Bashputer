#!/usr/bin/env bash
# bus_interconnect.sh

COMPONENT_NAME="Bus Interconnect"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/config.sh

NAME=""
printf -v 'ADDR' '0x%016X' 0

get_NAME_ADDR() {
    local addr=$1 i
    for i in "${!ADDR_LOW[@]}"; do 
        if (( ADDR_LOW[i] > addr )); then
            ADDR=$(( addr - ADDR_LOW[i-1] ))
            NAME="${NAMES[i-1]}"
            return 0
        fi
    done
}

parse_Load() {
    local addr=$1
    get_NAME_ADDR $addr
    echo "'$NAME' load '$ADDR'"
}

parse_Store() {
    local addr=$1
    get_NAME_ADDR $addr
    echo "'$NAME' store '$ADDR'"
}

parse_Input() {
    local type=$1 value=$2
    case $type in
        load) parse_Load $value ;;
        store) parse_Store $value ;;
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