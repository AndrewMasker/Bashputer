#!/usr/bin/env bash
# cpu.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/config.sh
source "$MY_DIR"/utils.sh
source "$MY_DIR"/cu.sh

# INITIALIZATION CODE
CPU_STATE=reset
PROC_STATE=none
SUBPROC_STATE=none
2SUBPROC_STATE=none
DATA_STATE=none

parse_Reset_CLK() {
    case $PROC_STATE in
        none) 
            PROC_STATE=load_cfgs
            ;;
        load_cfgs)  
            PC="$RESET_PC"
            SP="$RESET_SP"
            PROC_STATE=clear_registers
            ;;
        clear_registers)
            for ((i = 0; i < 256; i++)); do printf -v 'GPRs[i]' '0x%016X' 0; done
            printf -v 'OPCODE' '0x%016X' 0
            printf -v 'ARGA' '0x%016X' 0
            printf -v 'ARGB' '0x%016X' 0
            printf -v 'ARGC' '0x%016X' 0
            printf -v 'ARGD' '0x%016X' 0
            printf -v 'DATA' '0x%016X' 0
            PROC_STATE=done
            ;;
        done)
            CPU_STATE=ready
            PROC_STATE=none
            echo done
            ;;
        *) echo "cpu: unknown PROC_STATE '$PROC_STATE'" >&2 ;;
    esac
}

parse_Ready_CLK() {
    case $PROC_STATE in
        none) 
            PROC_STATE=request_opcode
            ;;
        request_opcode)
            echo load "$PC"
            PROC_STATE=load_opcode
            ;;
        load_opcode)
            OPCODE=$DATA
            PROC_STATE=parse_opcode
            ;;
        parse_opcode)
            parse_OPCODE
            ;;
        done)
            echo done
            PROC_STATE=none
            ;;
        *) echo "cpu: unknown PROC_STATE '$PROC_STATE'" >&2 ;;
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