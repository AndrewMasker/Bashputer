#!/usr/bin/env bash
# cu.sh

source "$MY_DIR"/alu.sh
source "$MY_DIR"/utils.h

parse_NOP_OPCODE() {
    printf -v PC '0x%016X' $((PC + 1))
    PROC_STATE=done
}

parse_HLT_OPCODE() {
    CPU_STATE=halted
    PROC_STATE=done
}

parse_ADD_OPCODE() {
    case $SUBPROC_STATE in
        none)
            SUBPROC_STATE=load
            ;;
        load)
            load_3_ARGS
            ;;
        add)
            GPRs[ARGC]=$(add "${GPRs[$ARGA]}" "${GPRs[$ARGB]}")
            printf -v 'PC' '0x%016X' $((PC + 1))
            SUBPROC_STATE=none
            PROC_STATE=done
            ;;
    esac
}

parse_OPCODE() {
    case $(get_Lower_Byte $OPCODE) in
        0x00) parse_NOP_OPCODE ;;
        0x01) parse_HLT_OPCODE ;;
        0x02) parse_ADD_OPCODE ;;
        0x03) parse_SUB_OPCODE ;;
        # 0x04) parse_INC_OPCODE ;;
        # 0x05) parse_DEC_OPCODE ;;
        # 0x07) parse_NEG_OPCODE ;;
        # 0x08) parse_MUL_OPCODE ;;
        # 0x09) parse_DIV_OPCODE ;;
        # 0x0A) parse_REM_OPCODE ;;
        0x0B) parse_AND_OPCODE ;;
        0x0C) parse_OR_OPCODE  ;;
        0x0D) parse_XOR_OPCODE ;;
        0x0E) parse_NOT_OPCODE ;;
        # 0x0F) parse_LSL_OPCODE ;;
        0x10) parse_LSR_OPCODE ;;
        0x11) parse_ASL_OPCODE ;;
        0x12) parse_ASR_OPCODE ;;
        # 0x13) parse_ROL_OPCODE ;;
        # 0x14) parse_LDB_OPCODE ;;
        # 0x15) parse_LDQ_OPCODE ;;
        # 0x16) parse_LDH_OPCODE ;;
        0x17) parse_LDW_OPCODE ;;
        # 0x18) parse_STB_OPCODE ;;
        # 0x19) parse_STQ_OPCODE ;;
        # 0x1A) parse_STH_OPCODE ;;
        0x1B) parse_STW_OPCODE ;;
        # 0x1C) parse_LIB_OPCODE ;;
        # 0x1D) parse_LIQ_OPCODE ;;
        # 0x1E) parse_LIH_OPCODE ;;
        0x1F) parse_LIW_OPCODE ;;
        0x20) parse_EQ_OPCODE  ;;
        # 0x21) parse_NE_OPCODE  ;;
        # 0x22) parse_LT_OPCODE  ;;
        0x23) parse_LTS_OPCODE ;;
        # 0x24) parse_LE_OPCODE  ;;
        # 0x25) parse_LES_OPCODE ;;
        0x26) parse_BZ_OPCODE  ;;
        0x27) parse_BNZ_OPCODE ;;
        0x28) parse_JMP_OPCODE ;;
        0x29) parse_PSH_OPCODE ;;
        0x2A) parse_POP_OPCODE ;;
        0x2B) parse_CAL_OPCODE ;;
        0x2C) parse_RET_OPCODE ;;
        0x2D) parse_MOV_OPCODE ;;
    esac
}