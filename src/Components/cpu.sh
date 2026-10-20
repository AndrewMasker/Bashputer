#!/usr/bin/env bash
# cpu.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/cpu.cfg

# INITIALIZATION CODE
CPU_STATE=reset
PROC_STATE=none
DATA_STATE=none

parse_Reset_CLK() {
    case $PROC_STATE in
        none) 
            PROC_STATE=load_pc 
            ;;
        load_pc)  
            PC="$RESET_PC"
            PROC_STATE=clear_GPRs
            ;;
        clear_GPRs)
            GPRs=( $(for i in {1..16}; do echo 0; done) )
            PROC_STATE=done
            ;;
        done)
            CPU_STATE=ready
            PROC_STATE=none
            echo done
            ;;
    esac
}

parse_Ready_CLK() {
    case $PROC_STATE in
        none) 
            PROC_STATE=load_inst
            ;;
        load_inst)
            echo load "$PC"
            PROC_STATE=do_inst
            ;;
        do_inst)
            parse_Inst
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