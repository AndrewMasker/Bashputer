#!/usr/bin/env bash
# cu.sh

source "$MY_DIR"/alu.sh
source "$MY_DIR"/utils.sh

parse_NOP_OPCODE() {
    local pidx=${1:-0}
    printf -v PC '0x%016X' $((PC + 1))
    if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
}

parse_HLT_OPCODE() {
    local pidx=${1:-0}
    CPU_STATE=halted
    if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
}

parse_ADD_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            add 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_SUB_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            sub 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_AND_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            and 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_OR_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            or 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_XOR_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            xor 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_NOT_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            not 'GPRs[ARGB]' "${GPRs[$ARGA]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_LSR_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            lsr 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_ASR_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            asr 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_SHL_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            shl 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_LDW_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MAR="${GPRs[$ARGA]}"
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "MAR" 0 true false
            ;;
        done_load_MDR_0)
            GPRs[ARGB]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_STW_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            MAR="${GPRs[$ARGB]}"
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            store_Word $((pidx+1)) "MAR" "MDR"
            ;;
        done_store_MAR_0)
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_LIW_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_EQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            eq 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_LTS_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            lts 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_BZ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            if (( GPRs[ARGA] == 0 )); then
                PC=${GPRs[ARGB]}
            else
                printf -v 'PC' '0x%016X' $((PC + 1))
            fi
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_BNZ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            if (( GPRs[ARGA] != 0 )); then
                PC=${GPRs[ARGB]}
            else
                printf -v 'PC' '0x%016X' $((PC + 1))
            fi
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_JMP_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            PC=${GPRs[ARGA]}
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_MOV_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            GPRs[ARGB]=${GPRs[ARGA]}
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
    esac
}

parse_OPCODE() {
    local pidx=${1:-0}
    case $OPCODE in
        0x00) parse_NOP_OPCODE $pidx ;;
        0x01) parse_HLT_OPCODE $pidx ;;
        0x02) parse_ADD_OPCODE $pidx ;;
        0x03) parse_SUB_OPCODE $pidx ;;
        # 0x04) parse_INC_OPCODE $pidx ;;
        # 0x05) parse_DEC_OPCODE $pidx ;;
        # 0x07) parse_NEG_OPCODE $pidx ;;
        # 0x08) parse_MUL_OPCODE $pidx ;;
        # 0x09) parse_DIV_OPCODE $pidx ;;
        # 0x0A) parse_REM_OPCODE $pidx ;;
        0x0B) parse_AND_OPCODE $pidx ;;
        0x0C) parse_OR_OPCODE  $pidx ;;
        0x0D) parse_XOR_OPCODE $pidx ;;
        0x0E) parse_NOT_OPCODE $pidx ;;
        # 0x0F) parse_LSL_OPCODE $pidx ;;
        0x10) parse_LSR_OPCODE $pidx ;;
        0x11) parse_ASR_OPCODE $pidx ;;
        0x12) parse_SHL_OPCODE $pidx ;;
        # 0x13) parse_ROL_OPCODE $pidx ;;
        # 0x14) parse_LDB_OPCODE $pidx ;;
        # 0x15) parse_LDQ_OPCODE $pidx ;;
        # 0x16) parse_LDH_OPCODE $pidx ;;
        0x17) parse_LDW_OPCODE $pidx ;;
        # 0x18) parse_STB_OPCODE $pidx ;;
        # 0x19) parse_STQ_OPCODE $pidx ;;
        # 0x1A) parse_STH_OPCODE $pidx ;;
        0x1B) parse_STW_OPCODE $pidx ;;
        # 0x1C) parse_LIB_OPCODE $pidx ;;
        # 0x1D) parse_LIQ_OPCODE $pidx ;;
        # 0x1E) parse_LIH_OPCODE $pidx ;;
        0x1F) parse_LIW_OPCODE $pidx ;;
        0x20) parse_EQ_OPCODE  $pidx ;;
        # 0x21) parse_NE_OPCODE  $pidx ;;
        # 0x22) parse_LT_OPCODE  $pidx ;;
        0x23) parse_LTS_OPCODE $pidx ;;
        # 0x24) parse_LE_OPCODE  $pidx ;;
        # 0x25) parse_LES_OPCODE $pidx ;;
        0x26) parse_BZ_OPCODE  $pidx ;;
        0x27) parse_BNZ_OPCODE $pidx ;;
        0x28) parse_JMP_OPCODE $pidx ;;
        # 0x29) parse_PSH_OPCODE $pidx ;;
        # 0x2A) parse_POP_OPCODE $pidx ;;
        # 0x2B) parse_CAL_OPCODE $pidx ;;
        # 0x2C) parse_RET_OPCODE $pidx ;;
        0x2D) parse_MOV_OPCODE $pidx ;;
        *) echo "cpu: unknown OPCODE '$OPCODE'" >&2; CPU_STATE=halted ;;
    esac
}