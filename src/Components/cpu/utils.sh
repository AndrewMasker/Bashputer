#!/usr/bin/env bash
# utils.sh

mask_Lower_Byte() {
    printf '%02X' $(( $1 & 0xFF )) 
}

load_3_ARGS() {
    case $2SUBPROC_STATE in
        none)
            2SUBPROC_STATE=RA
            ;;
        RA)
            PC=$(( PC + 1 ))
            echo load "$PC"
            2SUBPROC_STATE=LA
            ;;
        LA)
            ARGA=$DATA
            2SUBPROC_STATE=RB
            ;;
        RB)
            PC=$(( PC + 1 ))
            echo load "$PC"
            2SUBPROC_STATE=LB
            ;;
        LB)
            ARGB=$DATA
            2SUBPROC_STATE=RC
            ;;
        RC)
            PC=$(( PC + 1 ))
            echo load "$PC"
            2SUBPROC_STATE=LC
            ;;
        LC)
            ARGC=$DATA
            2SUBPROC_STATE=done
            ;;
        done)
            
        *) 
            echo "Unknow 2SUBPROC_STATE '$2SUBPROC_STATE'" ;;
    esac
}