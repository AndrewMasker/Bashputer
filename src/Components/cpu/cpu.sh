#!/usr/bin/env bash
# cpu.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/config.sh
source "$MY_DIR"/utils.sh
source "$MY_DIR"/cu.sh

# INITIALIZATION CODE
CPU_STATE=reset
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
        *) echo "cpu: unknown PROC_STATE '${PROC_STATE[pidx]}'" >&2 ;;
    esac
}

parse_Ready_CLK() {
    local pidx=${1:-0}
    case ${PROC_STATE[pidx]-} in
        "")
            echo load "$PC"
            PROC_STATE[pidx]=load_opcode
            ;;
        load_opcode)
            printf -v OPCODE '0x%02X' $(( DATA & 0xFF ))
            PROC_STATE[pidx]=parse_opcode
            ;;
        parse_opcode)
            parse_OPCODE $((pidx+1))
            ;;
        done_parse)
            echo done
            PROC_STATE[pidx]=""
            ;;
        *) echo "cpu: unknown PROC_STATE '${PROC_STATE[pidx]}'" >&2 ;;
    esac
}

parse_CLK() {
    case $CPU_STATE in
        reset) parse_Reset_CLK ;;
        ready) parse_Ready_CLK ;;
        stalled) : ;;
        halted) : ;;
        *) echo "cpu: unknown CPU_STATE '$CPU_STATE'" >&2 ;;
    esac
}

parse_Input() {
    local type=$1
    local value=$2
    case $type in
        clock) parse_CLK ;;
        reset) CPU_STATE=reset; PROC_STATE=() ;;
        stall) CPU_STATE=stalled ;;
        unstall) CPU_STATE=ready ;;
        data) DATA="$value" ;;
        data_valid) DATA_VALID=true
        *) echo "cpu: unknown input '$type'" >&2 ;; 
    esac
}

while read -r type value; do
    parse_Input "$type" "$value"
done