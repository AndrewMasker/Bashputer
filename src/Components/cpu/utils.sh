#!/usr/bin/env bash
# utils.sh

get_Lower_Byte() {
    printf '0x%02X' $(( $1 & 0xFF )) 
}


load_Byte() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"}
    local from=${3:-"PC"}
    local where=${4:-0}
    local clear=${5:-"true"}
    local increment=${6:-"true"}
    case ${PROC_STATE[pidx]-} in
        "")
            if $increment; then printf -v "$from" '0x%016X' $((${!from} + 1)); fi
            echo load "${!from}"
            if $clear; then printf -v "$to" '0x%016X' 0; fi
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            local prev
            printf -v "prev" '0x%016X' "${!to}"
            if ((where < 7)); then
                local upper_mask=$(( -1 << ( (where + 1)*8 ) ))
                local lower_mask=$(( ~( -1 << ( where*8 ) ) ))
                local mask=$(( (upper_mask) | (lower_mask) ))
                local data=$(( DATA << (where*8) ))
            else 
                local mask=-1
                local data=0
            fi
            printf -v "$to" '0x%016X' $(( (prev & mask) | data))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_$to_$where"; fi
            PROC_STATE[pidx]=""
            ;;
        *)
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

load_Quarter() {
    local pidx=${1:-0}
    local to=${2:-"ARGA"}
    local from=${3:-"PC"}
    local where=${4:-0}
    local clear=${5:-"true"}
    local increment=${6:-"true"}
    local byte_0_where=$(( 2*$where ))
    local byte_1_where=$(( byte_0_where + 1 ))
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $((pidx+1)) $to $from $byte_0_where $clear $increment
            ;;
        "done_load_$to_$byte_0_where")
            load_Byte $((pidx+1)) $to $byte_1_from $byte_1_where false true
            ;;
        "done_load_$to_$byte_1_where")
            printf -v "$from" '0x%016X' $(( ${!from} - 1 ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

load_2_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $(( pidx + 1)) ARGA
            ;;
        done_load_ARGA_0)
            load_Byte $(( pidx + 1)) ARGB
            ;;
        done_load_ARGB_0)
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
        done_load_ARGA_0)
            load_Byte $(( pidx + 1)) ARGB
            ;;
        done_load_ARGB_0)
            load_Byte $(( pidx + 1)) ARGC
            ;;
        done_load_ARGC_0)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}

