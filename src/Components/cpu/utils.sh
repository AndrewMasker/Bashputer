#!/usr/bin/env bash
# utils.sh

get_Lower_Byte() {
    printf '0x%02X' $(( $1 & 0xFF )) 
}

load_Byte() {
    local where=${1:-"ARGA"}
    local pidx=${2:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            echo load "$PC"
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            local prev
            printf -v "prev" '0x%016X' "$where"
            local mask=$((-1 << 8))
            printf -v "$where" '0x%016X' $(( (prev & mask) | DATA))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_'$where'"; fi
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
            printf -v 'PC' '0x%016X' $((PC + 1))
            printf -v "ARGA" '0x%016X' 0
            PROC_STATE[pidx]=LA
            ;;
        LA)
            load_Byte ARGA $(( pidx + 1))
            ;;
        done_load_ARGA)
            printf -v 'PC' '0x%016X' $((PC + 1))
            printf -v "ARGB" '0x%016X' 0
            PROC_STATE[pidx]=LB
            ;;
        LB)
            load_Byte ARGB $(( pidx + 1))
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
            printf -v 'PC' '0x%016X' $((PC + 1))
            printf -v "ARGA" '0x%016X' 0
            PROC_STATE[pidx]=LA
            ;;
        LA)
            load_Byte ARGA $(( pidx + 1))
            ;;
        done_load_ARGA)
            printf -v 'PC' '0x%016X' $((PC + 1))
            printf -v "ARGB" '0x%016X' 0
            PROC_STATE[pidx]=LB
            ;;
        LB)
            load_Byte ARGB $(( pidx + 1))
            ;;
        done_load_ARGB)
            printf -v 'PC' '0x%016X' $((PC + 1))
            printf -v "ARGC" '0x%016X' 0
            PROC_STATE[pidx]=LC
            ;;
        LC)
            load_Byte ARGC $(( pidx + 1))
            ;;
        done_load_ARGC)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}