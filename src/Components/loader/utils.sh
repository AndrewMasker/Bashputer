#!/usr/bin/env bash
# utils.sh

get_Byte() {
    local addr=$1 path
    path="$MY_DIR"/../../Cartridges/"${cartridges[CART_BYTE]}/hex"
    if [[ ! -f $path ]]; then 
        LOADER_STATE=""
        BUSY_STATE=0x00
        RESULT_STATE=0x05
        PROC_STATE[pidx]=""
        return 0
    fi
    
}