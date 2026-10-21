#!/usr/bin/env bash
# utils.sh

get_Lower_Byte() {
    printf '0x%02X' $(( $1 & 0xFF )) 
}

load_Byte() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"}
    local from=${3:-"PC"}
    local clear=${4:-"true"}
    local increment=${5:-"pre"}
    case ${PROC_STATE[pidx]-} in
        "")
            if [[ $increment == "pre" ]]; then printf -v "$from" '0x%016X' $((${!from} + 1)); fi
            echo load "${!from}"
            if [[ $increment == "post "]]; then printf -v "$from" '0x%016X' $((${!from} + 1)); fi
            if $clear; then printf -v "$to" '0x%016X' 0; fi
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            local prev
            printf -v "prev" '0x%016X' "${!to}"
            local mask=$((-1 << 8))
            printf -v "$to" '0x%016X' $(( (prev & mask) | DATA))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_$to"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_2_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $(( pidx + 1)) ARGA
            ;;
        done_load_ARGA)
            load_Byte $(( pidx + 1)) ARGB
            ;;
        done_load_ARGB)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_3_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $(( pidx + 1)) ARGA
            ;;
        done_load_ARGA)
            load_Byte $(( pidx + 1)) ARGB
            ;;
        done_load_ARGB)
            load_Byte $(( pidx + 1)) ARGC
            ;;
        done_load_ARGC)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}