#!/usr/bin/env bash
# cpu.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/config.sh
source "$MY_DIR"/utils.sh
source "$MY_DIR"/cu.sh

# INITIALIZATION CODE
CPU_STATE=reset
PROC_STATE=()
DATA_STATE=none

parse_Reset_CLK() {
    local i
    local pidx=${1-}
    case ${PROC_STATE[pidx]-} in
        "") 
            PROC_STATE[pidx]=load_cfgs
            ;;
        load_cfgs)  
            PC="$RESET_PC"
            SP="$RESET_SP"
            PROC_STATE[pidx]=clear_registers
            ;;
        clear_registers)
            GPRs=()
            for ((i = 0; i < 256; i++)); do printf -v 'GPRs[i]' '0x%016X' 0; done
            printf -v 'OPCODE' '0x%016X' 0
            printf -v 'ARGA' '0x%016X' 0
            printf -v 'ARGB' '0x%016X' 0
            printf -v 'ARGC' '0x%016X' 0
            printf -v 'ARGD' '0x%016X' 0
            printf -v 'DATA' '0x%016X' 0
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
    local pidx=${1-}
    case ${PROC_STATE[pidx]-} in
        "") 
            PROC_STATE[pidx]=request_opcode
            ;;
        request_opcode)
            echo load "$PC"
            PROC_STATE[pidx]=load_opcode
            ;;
        load_opcode)
            OPCODE=$DATA
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
        halted) echo halted ;;
        *) echo "cpu: unknown CPU_STATE '$CPU_STATE'" >&2 ;;
    esac
}

parse_Data() {
    DATA=$1
}

parse_Input() {
    local type=$1
    local value=$2
    case $type in
        clock_pulse) parse_CLK ;;
        data) parse_Data "$value" ;;
        *) echo "cpu: unknown input '$type'" >&2 ;; 
    esac
}

while read -r type value; do
    parse_Input "$type" "$value"
done