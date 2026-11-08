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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
    esac
}

parse_INC_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            inc "GPRs[$ARGA]"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_DEC_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            dec "GPRs[$ARGA]"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_NEG_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            neg 'GPRs[ARGB]' "${GPRs[$ARGA]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_MUL_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            mul 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_DIV_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            div 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_REM_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            rem 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
    esac
}

parse_LDB_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MAR="${GPRs[$ARGA]}"
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            load_Byte $((pidx+1)) "MDR" "MAR" 0 true false
            ;;
        done_load_MDR_0)
            GPRs[ARGB]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LDQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MAR="${GPRs[$ARGA]}"
            PROC_STATE[pidx]="load_quarter"
            ;;
        load_quarter)
            load_Quarter $((pidx+1)) "MDR" "MAR" 0 true false
            ;;
        done_load_MDR_0)
            GPRs[ARGB]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LDH_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MAR="${GPRs[$ARGA]}"
            PROC_STATE[pidx]="load_half"
            ;;
        load_half)
            load_Half $((pidx+1)) "MDR" "MAR" 0 true false
            ;;
        done_load_MDR_0)
            GPRs[ARGB]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
    esac
}

parse_STB_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            MAR="${GPRs[$ARGB]}"
            PROC_STATE[pidx]="store_byte"
            ;;
        store_byte)
            store_Byte $((pidx+1)) "MAR" "MDR"
            ;;
        done_store_MAR_0)
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_STQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            MAR="${GPRs[$ARGB]}"
            PROC_STATE[pidx]="store_quarter"
            ;;
        store_quarter)
            store_Quarter $((pidx+1)) "MAR" "MDR"
            ;;
        done_store_MAR_0)
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_STH_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_2_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            MAR="${GPRs[$ARGB]}"
            PROC_STATE[pidx]="store_half"
            ;;
        store_half)
            store_Half $((pidx+1)) "MAR" "MDR"
            ;;
        done_store_MAR_0)
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
            PROC_STATE[pidx]="store_word"
            ;;
        store_word)
            store_Word $((pidx+1)) "MAR" "MDR"
            ;;
        done_store_MAR_0)
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LIB_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            load_Byte $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LIQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            PROC_STATE[pidx]="load_quarter"
            ;;
        load_quarter)
            load_Quarter $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LIH_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            PROC_STATE[pidx]="load_half"
            ;;
        load_half)
            load_Half $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
    esac
}

parse_NEQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            neq 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LT_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            lt 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
    esac
}

parse_LE_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            le 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_LES_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_3_ARGS $((pidx+1))
            ;;
        done_load)
            les 'GPRs[ARGC]' "${GPRs[$ARGA]}" "${GPRs[$ARGB]}"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
                printf -v 'PC' '0x%016X' $(( ${GPRs[ARGB]} + JO ))
            else
                printf -v 'PC' '0x%016X' $((PC + 1))
            fi
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
                printf -v 'PC' '0x%016X' $(( ${GPRs[ARGB]} + JO ))
            else
                printf -v 'PC' '0x%016X' $((PC + 1))
            fi
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_JMP_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v 'PC' '0x%016X' $(( ${GPRs[ARGA]} + JO ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_PSHB_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            printf -v SP '0x%016X' $(( SP + 1 ))
            PROC_STATE[pidx]="store_byte"
            ;;
        store_byte)
            store_Byte $((pidx+1)) "SP" "MDR"
            ;;
        done_store_SP_0)
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_PSHQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            printf -v SP '0x%016X' $(( SP + 1 ))
            PROC_STATE[pidx]="store_quarter"
            ;;
        store_quarter)
            store_Quarter $((pidx+1)) "SP" "MDR"
            ;;
        done_store_SP_0)
            printf -v SP '0x%016X' $(( SP + 1 ))
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_PSHH_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            printf -v SP '0x%016X' $(( SP + 1 ))
            PROC_STATE[pidx]="store_half"
            ;;
        store_half)
            store_Half $((pidx+1)) "SP" "MDR"
            ;;
        done_store_SP_0)
            printf -v SP '0x%016X' $(( SP + 3 ))
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_PSHW_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            MDR="${GPRs[$ARGA]}"
            printf -v SP '0x%016X' $(( SP + 1 ))
            PROC_STATE[pidx]="store_word"
            ;;
        store_word)
            store_Word $((pidx+1)) "SP" "MDR"
            ;;
        done_store_SP_0)
            printf -v SP '0x%016X' $(( SP + 7 ))
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_POPB_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v SP '0x%016X' $(( SP - 1 ))
            PROC_STATE[pidx]="load_byte"
            ;;
        load_byte)
            load_Byte $((pidx+1)) "MDR" "SP" 0 true true
            ;;
        done_load_MDR_0)
            printf -v SP '0x%016X' $(( SP - 1 ))
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_POPQ_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v SP '0x%016X' $(( SP - 2 ))
            PROC_STATE[pidx]="load_quarter"
            ;;
        load_quarter)
            load_Quarter $((pidx+1)) "MDR" "SP" 0 true true
            ;;
        done_load_MDR_0)
            printf -v SP '0x%016X' $(( SP - 2 ))
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_POPH_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v SP '0x%016X' $(( SP - 4 ))
            PROC_STATE[pidx]="load_half"
            ;;
        load_half)
            load_Half $((pidx+1)) "MDR" "SP" 0 true true
            ;;
        done_load_MDR_0)
            printf -v SP '0x%016X' $(( SP - 4 ))
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_POPW_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v SP '0x%016X' $(( SP - 8 ))
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "SP" 0 true true
            ;;
        done_load_MDR_0)
            printf -v SP '0x%016X' $(( SP - 8 ))
            GPRs[ARGA]=$MDR
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_CAL_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            MAR="$PC"
            printf -v SP '0x%016X' $(( SP + 1 ))
            PROC_STATE[pidx]="store_word"
            ;;
        store_word)
            store_Word $((pidx+1)) "SP" "MAR"
            ;;
        done_store_SP_0)
            printf -v SP '0x%016X' $(( SP + 7 ))
            printf -v 'PC' '0x%016X' $(( ${GPRs[ARGA]} + JO ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_CALI_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            MAR="$PC"
            printf -v SP '0x%016X' $(( SP + 1 ))
            PROC_STATE[pidx]="store_word"
            ;;
        store_word)
            store_Word $((pidx+1)) "SP" "MAR"
            ;;
        done_store_SP_0)
            printf -v SP '0x%016X' $(( SP + 7 ))
            printf -v 'PC' '0x%016X' $(( MDR + JO ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_RET_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            printf -v SP '0x%016X' $(( SP - 8 ))
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "SP" 0 true true
            ;;
        done_load_MDR_0)
            printf -v SP '0x%016X' $(( SP - 8 ))
            printf -v 'PC' '0x%016X' $(( MDR + 1 ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
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
        *) bad_State $pidx ;;
    esac
}

parse_PC_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v 'GPRs[ARGA]' '0x%016X' $(( PC - 1 ))
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_SP_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            GPRs[ARGA]="$SP"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_SJO_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            JO=${GPRs[ARGA]}
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_JMPI_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            printf -v 'PC' '0x%016X' $(( MDR + JO ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_BZI_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            load_Word $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            if (( ${GPRs[ARGA]} == 0 )); then
                printf -v 'PC' '0x%016X' $(( MDR + JO ))
            else
                printf -v 'PC' '0x%016X' $((PC + 1))
            fi
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_BNZI_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            load_Word $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            if (( ${GPRs[ARGA]} != 0 )); then
                printf -v 'PC' '0x%016X' $(( MDR + JO ))
            else
                printf -v 'PC' '0x%016X' $((PC + 1))
            fi
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_SSP_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            printf -v 'SP' '0x%016X' $(( ${GPRs[ARGA]} ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_SSPI_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PROC_STATE[pidx]="load_word"
            ;;
        load_word)
            load_Word $((pidx+1)) "MDR" "PC" 0 true true
            ;;
        done_load_MDR_0)
            printf -v 'SP' '0x%016X' $(( MDR ))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_XSP_OPCODE() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_1_ARGS $((pidx+1))
            ;;
        done_load)
            local tmp="$SP"
            SP="${GPRs[ARGA]}"
            GPRs[ARGA]="$tmp"
            printf -v 'PC' '0x%016X' $((PC + 1))
            if (( pidx > 0 )); then PROC_STATE[pidx-1]="done_parse"; fi
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_OPCODE() {
    local pidx=${1:-0}
    case $OPCODE in
        0x00) parse_NOP_OPCODE $pidx ;;
        0x01) parse_HLT_OPCODE $pidx ;;
        0x02) parse_ADD_OPCODE $pidx ;;
        0x03) parse_SUB_OPCODE $pidx ;;
        0x04) parse_INC_OPCODE $pidx ;;
        0x05) parse_DEC_OPCODE $pidx ;;
        # 0x06 UNMAPPED $pidx ;;
        0x07) parse_NEG_OPCODE $pidx ;;
        0x08) parse_MUL_OPCODE $pidx ;;
        0x09) parse_DIV_OPCODE $pidx ;;
        0x0A) parse_REM_OPCODE $pidx ;;

        0x0B) parse_AND_OPCODE $pidx ;;
        0x0C) parse_OR_OPCODE  $pidx ;;
        0x0D) parse_XOR_OPCODE $pidx ;;
        0x0E) parse_NOT_OPCODE $pidx ;;

        # 0x0F) UNMAPPED $pidx ;;
        
        0x10) parse_LSR_OPCODE $pidx ;;
        0x11) parse_ASR_OPCODE $pidx ;;
        0x12) parse_SHL_OPCODE $pidx ;;

        # 0x13) UNMAPPED $pidx ;;

        0x14) parse_LDB_OPCODE $pidx ;;
        0x15) parse_LDQ_OPCODE $pidx ;;
        0x16) parse_LDH_OPCODE $pidx ;;
        0x17) parse_LDW_OPCODE $pidx ;;

        0x18) parse_STB_OPCODE $pidx ;;
        0x19) parse_STQ_OPCODE $pidx ;;
        0x1A) parse_STH_OPCODE $pidx ;;
        0x1B) parse_STW_OPCODE $pidx ;;
        
        0x1C) parse_LIB_OPCODE $pidx ;;
        0x1D) parse_LIQ_OPCODE $pidx ;;
        0x1E) parse_LIH_OPCODE $pidx ;;
        0x1F) parse_LIW_OPCODE $pidx ;;
        
        0x20) parse_EQ_OPCODE  $pidx ;;
        0x21) parse_NEQ_OPCODE  $pidx ;;
        0x22) parse_LT_OPCODE  $pidx ;;
        0x23) parse_LTS_OPCODE $pidx ;;
        0x24) parse_LE_OPCODE  $pidx ;;
        0x25) parse_LES_OPCODE $pidx ;;

        0x26) parse_BZ_OPCODE  $pidx ;;
        0x27) parse_BNZ_OPCODE $pidx ;;
        0x28) parse_JMP_OPCODE $pidx ;;

        0x29) parse_PSHB_OPCODE $pidx ;;
        0x2A) parse_PSHQ_OPCODE $pidx ;;
        0x2B) parse_PSHH_OPCODE $pidx ;;
        0x2C) parse_PSHW_OPCODE $pidx ;;

        0x2E) parse_POPB_OPCODE $pidx ;;
        0x2F) parse_POPQ_OPCODE $pidx ;;
        0x30) parse_POPH_OPCODE $pidx ;;
        0x31) parse_POPW_OPCODE $pidx ;;

        0x32) parse_CAL_OPCODE $pidx ;;
        0x33) parse_CALI_OPCODE $pidx ;;
        0x34) parse_RET_OPCODE $pidx ;;

        0x35) parse_MOV_OPCODE $pidx ;;
        0x36) parse_PC_OPCODE $pidx ;;
        0x37) parse_SP_OPCODE $pidx ;;

        0x38) parse_SJO_OPCODE $pidx ;;
        0x39) parse_JMPI_OPCODE $pidx ;;
        0x3A) parse_BZI_OPCODE $pidx ;;
        0x3B) parse_BNZI_OPCODE $pidx ;;

        0x3C) parse_SSP_OPCODE $pidx ;;
        0x3D) parse_SSPI_OPCODE $pidx ;;
        0x3E) parse_XSP_OPCODE $pidx ;;

        *) parse_HLT_OPCODE $pidx ;;
    esac
}