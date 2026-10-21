#!/usr/bin/env bash
# alu.sh

add() {
    printf '0x%016X' $(( $1 + $2 ))
}

sub() {
    printf '0x%016X' $(( $1 - $2 ))
}

and() {
    printf '0x%016X' $(( $1 & $2 ))
}

or() {
    printf '0x%016X' $(( $1 | $2 ))
}

xor() {
    printf '0x%016X' $(( $1 ^ $2 ))
}

not() {
    printf '0x%016X' $(( ~$1 ))
}

lsr() {
    if (( $2 == 0)); then printf '0x%016X' $(( $1 )); fi
    if (( $2 >= 64)); then printf '0x%016X' 0; fi
    local asr=$(( $1 >> $2 ))
    local mask=$(( ~( -1 <<  (64 - $2) ) ))
    printf '0x%016X' $(( asr &  mask))
}

asr() {
    printf '0x%016X' $(( $1 >> $2 ))
}

shl() {
    printf '0x%016X' $(( $1 << $2 ))
}

