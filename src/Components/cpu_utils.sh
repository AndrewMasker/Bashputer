#!/usr/bin/env bash
# cpu_utils.sh

mask_Lower_Byte() {
    printf '%02X' $(( $1 & 0xFF )) 
}