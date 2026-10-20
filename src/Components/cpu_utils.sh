#!/usr/bin/env bash
# cpu_utils.sh

mask_Lower_Byte() {
    printf -v masked '%02X' $(( $1 && 0xFF )) 
    echo masked
}