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
    if (( $2 == 0)); then printf '0x%016X' $(( $1 )); return; fi
    if (( $2 >= 64)); then printf '0x%016X' 0; return; fi
    local asr=$(( $1 >> $2 ))
    local mask=$(( ~( -1 <<  (64 - $2) ) ))
    printf '0x%016X' $(( asr &  mask))
}

asr() {
    local shifts=$2
    if (( shifts < 0 )); then $shifts=0;
    else (( shifts > 63)); then $shifts=63; fi
    printf '0x%016X' $(( $1 >> shifts ))
}

shl() {
    local shifts=$2
    if (( shifts < 0 )); then $shifts=0;
    else (( shifts > 63)); then $shifts=63; fi
    printf '0x%016X' $(( $1 << shifts ))
}

eq() {
    printf '0x%016X' $(( $1 == $2 ))
}

lts() {
    printf '0x%016X' $(( $1 < $2))
}

