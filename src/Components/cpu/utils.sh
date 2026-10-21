#!/usr/bin/env bash
# utils.sh

get_Lower_Byte() {
    printf '0x%02X' $(( $1 & 0xFF )) 
}

load_2_ARGS() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PROC_STATE[pidx]=RA
            ;;
        RA)
            printf -v 'PC' '0x%016X' $((PC + 1))
            echo load "$PC"
            PROC_STATE[pidx]=LA
            ;;
        LA)
            ARGA=$DATA
            PROC_STATE[pidx]=RB
            ;;
        RB)
            printf -v 'PC' '0x%016X' $((PC + 1))
            echo load "$PC"
            PROC_STATE[pidx]=LB
            ;;
        LB)
            ARGB=$DATA
            PROC_STATE[pidx]=done
            ;;
        done)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_args"; fi
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
            PROC_STATE[pidx]=RA
            ;;
        RA)
            printf -v 'PC' '0x%016X' $((PC + 1))
            echo load "$PC"
            PROC_STATE[pidx]=LA
            ;;
        LA)
            ARGA=$DATA
            PROC_STATE[pidx]=RB
            ;;
        RB)
            printf -v 'PC' '0x%016X' $((PC + 1))
            echo load "$PC"
            PROC_STATE[pidx]=LB
            ;;
        LB)
            ARGB=$DATA
            PROC_STATE[pidx]=RC
            ;;
        RC)
            printf -v 'PC' '0x%016X' $((PC + 1))
            echo load "$PC"
            PROC_STATE[pidx]=LC
            ;;
        LC)
            ARGC=$DATA
            PROC_STATE[pidx]=done
            ;;
        done)
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_load_args"; fi
            PROC_STATE[pidx]=""
            ;;
        *) 
            echo "Unknown PROC_STATE '${PROC_STATE[pidx]}'" ;;
    esac
}