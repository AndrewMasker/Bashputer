#!/usr/bin/env bash
# cpu.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/cpu.cfg
source "$MY_DIR"/cpu_utils.sh

# INITIALIZATION CODE
CPU_STATE=reset
PROC_STATE=none
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
            GPRs=( $(for i in {1..256}; do echo 0; done) )
            OPCODE=0x0
            ARGA=0x0
            ARGB=0x0
            ARGC=0x0
            ARGD=0x0
            PROC_STATE=done
            ;;
        done)
            CPU_STATE=ready
            PROC_STATE=none
            echo done
            ;;
    esac
}

parse_OPCODE() {
    case $(mask_Lower_Byte $OPCODE) in
        00) parse_NOP_OPCODE ;;
        01) parse_HLT_OPCODE ;;
        02) parse_ADD_OPCODE ;;
       #03) parse_SUB_OPCODE ;;
       #04) parse_INC_OPCODE ;;
       #05) parse_DEC_OPCODE ;;
        07) parse_NEG_OPCODE ;;
        08) parse_MUL_OPCODE ;;
       #09) parse_DIV_OPCODE ;;
       #0A) parse_REM_OPCODE ;;
        0B) parse_AND_OPCODE ;;
        0C) parse_OR_OPCODE  ;;
        0D) parse_XOR_OPCODE ;;
       #0E) parse_NOT_OPCODE ;;
        0F) parse_LSL_OPCODE ;;
        10) parse_LSR_OPCODE ;;
       #11) parse_ASL_OPCODE ;;
       #12) parse_ASR_OPCODE ;;
       #13) parse_ROL_OPCODE ;;
       #14) parse_LDB_OPCODE ;;
       #15) parse_LDQ_OPCODE ;;
       #16) parse_LDH_OPCODE ;;
        17) parse_LDW_OPCODE ;;
       #18) parse_STB_OPCODE ;;
       #19) parse_STQ_OPCODE ;;
       #1A) parse_STH_OPCODE ;;
        1B) parse_STW_OPCODE ;;
       #1C) parse_SEB_OPCODE ;;
       #1D) parse_SEQ_OPCODE ;;
       #1E) parse_SEH_OPCODE ;;
        1F) parse_SEW_OPCODE ;;
        20) parse_EQ_OPCODE  ;;
        21) parse_NE_OPCODE  ;;
        22) parse_LT_OPCODE  ;;
        23) parse_LTS_OPCODE ;;
        24) parse_LE_OPCODE  ;;
        25) parse_LES_OPCODE ;;
        26) parse_BZ_OPCODE  ;;
        27) parse_BNZ_OPCODE ;;
        28) parse_JMP_OPCODE ;;
        29) parse_PSH_OPCODE ;;
        2A) parse_POP_OPCODE ;;
        2B) parse_CAL_OPCODE ;;
        2C) parse_RET_OPCODE ;;




    esac
}

parse_Ready_CLK() {
    case $PROC_STATE in
        none) 
            PROC_STATE=load_opcode
            ;;
        load_opcode)
            echo load "$PC"
            PROC_STATE=parse_opcode
            ;;
        parse_opcode)
            parse_OPCODE
            ;;
    esac
}

parse_CLK() {
    case $CPU_STATE in
        reset) parse_Reset_CLK ;;
        ready) parse_Ready_CLK ;;
    esac
}

parse_Data() {
    local value=$1
    case $DATA_STATE in
        init) 
    esac

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