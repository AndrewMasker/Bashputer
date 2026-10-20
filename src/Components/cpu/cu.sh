#!/usr/bin/env bash
# cu.sh

parse_NOP_OPCODE() {
    PC=$((PC + 1))
    PROC_STATE=done
}

parse_HLT_OPCODE() {
    CPU_STATE=halted
    PROC_STATE=done
}

parse_ADD_OPCODE() {
    case $SUBPROC_STATE in
        none)
            SUBPROC_STATE=RA
            ;;
        RA)
            echo "load '$((PC + 1))'"
            SUBPROC_STATE=LA
            ;;
        LA)
            ARGA=$DATA
            SUBPROC_STATE=RB
            ;;
        RB)
            echo "load '$((PC + 2))'"
            SUBPROC_STATE=LB
            ;;
        LB)
            ARGB=$DATA
            SUBPROC_STATE=RC
            ;;
        RC)
            echo "load '$((PC + 3))'"
            SUBPROC_STATE=LC
            ;;
        LC)
            ARGC=$DATA
            SUBPROC_STATE=ADD
            ;;
        add)
            GPRs[ARGC]=$((add ${GPRs[$ARGA]} ${GPRs[$ARGB]})) 
            SUBPROC_STATE=none
            PROC_STATE=done
            ;;
    esac
    
}

parse_OPCODE() {
    case $(mask_Lower_Byte $OPCODE) in
        00) parse_NOP_OPCODE ;;
        01) parse_HLT_OPCODE ;;
        02) parse_ADD_OPCODE ;;
        # 03) parse_SUB_OPCODE ;;
        # 04) parse_INC_OPCODE ;;
        # 05) parse_DEC_OPCODE ;;
        07) parse_NEG_OPCODE ;;
        # 08) parse_MUL_OPCODE ;;
        # 09) parse_DIV_OPCODE ;;
        # 0A) parse_REM_OPCODE ;;
        0B) parse_AND_OPCODE ;;
        0C) parse_OR_OPCODE  ;;
        0D) parse_XOR_OPCODE ;;
        0E) parse_NOT_OPCODE ;;
        # 0F) parse_LSL_OPCODE ;;
        # 10) parse_LSR_OPCODE ;;
        11) parse_ASL_OPCODE ;;
        12) parse_ASR_OPCODE ;;
        # 13) parse_ROL_OPCODE ;;
        # 14) parse_LDB_OPCODE ;;
        # 15) parse_LDQ_OPCODE ;;
        # 16) parse_LDH_OPCODE ;;
        17) parse_LDW_OPCODE ;;
        # 18) parse_STB_OPCODE ;;
        # 19) parse_STQ_OPCODE ;;
        # 1A) parse_STH_OPCODE ;;
        1B) parse_STW_OPCODE ;;
        # 1C) parse_LIB_OPCODE ;;
        # 1D) parse_LIQ_OPCODE ;;
        # 1E) parse_LIH_OPCODE ;;
        1F) parse_LIW_OPCODE ;;
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