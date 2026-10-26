#!/usr/bin/env bash
# utils.sh

is_2_Digit_Hex() {
    local format='^0x[[0-9A-F]]{2}$'
    [[ $1 =~ $format ]] # Returns 0 if this is true and returns 1 if not
}

is_16_Digit_Hex() {
    local format='^0x[[0-9A-F]]{16}$'
    [[ $1 =~ $format ]] # Returns 0 if this is true and returns 1 if not
}