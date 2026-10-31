#!/usr/bin/env bash
# utils.sh

get_Byte() {
    local pidx=${1:-0} addr=$2 path
    path="$MY_DIR"/../../Cartridges/"${cartridges[CART_BYTE]}/hex"
    case ${PROC_STATE[pidx]-} in
        "")    
            if [[ ! -f $path ]]; then 
                die "Cartridge path does not exist for cartridge '${cartridges[CART_BYTE]}'"
            fi
            
            ;;
    esac
}