#!/usr/bin/env bash
# cpu.sh

COMPONENT_NAME=CPU

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/config.sh
source "$MY_DIR"/utils.sh
source "$MY_DIR"/cu.sh

# INITIALIZATION CODE
CPU_STATE=reset
RESUME_STATE=reset
PROC_STATE=()

parse_Reset_CLK() {
    local i
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            PC="$RESET_PC"
            SP="$RESET_SP"
            PROC_STATE[pidx]=clear_registers
            ;;
        clear_registers)
            GPRs=()
            for ((i = 0; i < 256; i++)); do printf -v 'GPRs[i]' '0x%016X' 0; done
            printf -v 'OPCODE' '0x%016X' 0 # Byte register holding the current instruction opcode
            printf -v 'ARGA' '0x%016X' 0
            printf -v 'ARGB' '0x%016X' 0
            printf -v 'ARGC' '0x%016X' 0
            printf -v 'ARGD' '0x%016X' 0
            printf -v 'DATA' '0x%016X' 0
            DATA_VALID=false
            printf -v 'MAR' '0x%016X' 0
            printf -v 'MDR' '0x%016X' 0
            PROC_STATE[pidx]=done
            ;;
        done)
            CPU_STATE=ready
            PROC_STATE[pidx]=""
            echo done
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_Ready_CLK() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            load_Byte $((pidx+1)) OPCODE PC 0 true false '0x%02X'
            ;;
        done_load_OPCODE_0)
            parse_OPCODE $((pidx+1))
            ;;
        done_parse)
            echo done
            PROC_STATE[pidx]=""
            ;;
        *) bad_State $pidx ;;
    esac
}

parse_CLK() {
    case $CPU_STATE in
        reset) parse_Reset_CLK ;;
        ready) parse_Ready_CLK ;;
        stalled) : ;;
        halted) : ;;
        *) die "unknown CPU_STATE '$CPU_STATE'" ;;
    esac
}

parse_Input() {
    local type=$1
    local value=${2-}
    case $type in
        clock) parse_CLK ;;
        reset) CPU_STATE=reset; PROC_STATE=() ;;
        stall) [[ $CPU_STATE == "stalled" ]] || { RESUME_STATE=$CPU_STATE ; CPU_STATE=stalled; } ;;
        unstall) [[ $CPU_STATE == "stalled" ]] && CPU_STATE=$RESUME_STATE ;;
        data) DATA="$value"; DATA_VALID=true ;; 
        *) die "unknown input type '$type' with value '$value'" ;;
    esac
}

run_CPU() {
    while read -r type value; do
        parse_Input "$type" "$value"
    done
}

dump_State() {
    local i 
    printf 'CPU STATE: \n'
    printf '    CPU_STATE=%s RESUME_STATE=%s\n' "${CPU_STATE-unset}" "${RESUME_STATE-unset}"
    printf '    PC=%s SP=%s OPCODE=%s\n' "${PC-unset}" "${SP-unset}" "${OPCODE-unset}"
    printf '    ARGA=%s ARGB=%s ARGC=%s\n' "${ARGA-unset}" "${ARGB-unset}" "${ARGC-unset}"
    printf '    MAR=%s MDR=%s DATA=%s DATA_VALID=%s\n' "${MAR-unset}" "${MDR-unset}" "${DATA-unset}" "${DATA_VALID-unset}"
    printf '    PROC_STATE=(%s)\n' "${PROC_STATE[*]@Q}"
    printf '    Nonzero GPRs:\n'
    for i in "${!GPRs[@]}"; do
        if (( GPRs[i] != 0 )); then printf '        r%d=%s\n' "$i" "${GPRs[i]}"; fi
    done
}

run_CPU
