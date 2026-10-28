#!/usr/bin/env bash
# timer.sh

COMPONENT_NAME="Timer"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh
source "$MY_DIR"/config.sh

export LC_ALL=C
exec {SLEEP_FD}<> <(:)

reset() {
    printf -v start_us '%d' "${EPOCHREALTIME/./}"
}

get_Ticks() {
    printf -v ticks '0x%016X' $(( (${EPOCHREALTIME/./} - start_us) / US_PER_TICK ))
}

parse_Load() {
    local addr=$1 byte_num tmp
    if (( addr >= LOW_ADDR && addr < (LOW_ADDR + 8) )); then
        byte_num=$(( (addr - LOW_ADDR) ))
        if (( byte_num == 0)); then
            printf -v tmp '0x%02X' $(( ticks & 0xFF ))
        else
            printf -v tmp '0x%02X' $(( (ticks >> (byte_num*8)) & 0xFF ))
        fi  
        echo "data $tmp"
    else
        echo "data $UNMAPPED_DATA"
    fi
}

parse_Store() {
    local addr=$1
    case $addr in
        "$RESET_ADDR")
            reset
            ;;
        "$TRIGGER_ADDR")
            get_Ticks
            ;;
    esac
}

parse_Input() {
    local type=$1 value=$2
    case $type in
        load) parse_Load "$value" ; echo done ;;
        store) parse_Store $value ; echo done ;;
        *) die "unknown input type" ;;
    esac
}

run_TIMER() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

reset
get_Ticks
run_TIMER

