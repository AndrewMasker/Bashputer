#!/usr/bin/env bash
# utils.sh

mask_Lower_Byte() {
    printf '%02X' $(( $1 & 0xFF )) 
}