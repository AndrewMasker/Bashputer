#!/usr/bin/env bash
# alu.sh

add() {
    printf -v "$1" '0x%016X' $(( $2 + $3 ))
}

sub() {
    printf -v "$1" '0x%016X' $(( $2 - $3 ))
}

and() {
    printf -v "$1" '0x%016X' $(( $2 & $3 ))
}

or() {
    printf -v "$1" '0x%016X' $(( $2 | $3 ))
}

xor() {
    printf -v "$1" '0x%016X' $(( $2 ^ $3 ))
}

not() {
    printf -v "$1" '0x%016X' $(( ~$2 ))
}

lsr() {
    if (( $3 == 0)); then printf -v "$1" '0x%016X' $(( $2 )); return; fi
    if (( $3 >= 64)); then printf -v "$1" '0x%016X' 0; return; fi
    local asr=$(( $2 >> $3 ))
    local mask=$(( ~( -1 <<  (64 - $3) ) ))
    printf -v "$1" '0x%016X' $(( asr &  mask))
}

asr() {
    local shifts=$3
    if (( shifts >= 64 || shifts < 0 )); then shifts=63; fi
    printf -v "$1" '0x%016X' $(( $2 >> shifts ))
}

shl() {
    local shifts=$3
    if (( shifts >= 64 || shifts < 0 )); then printf -v "$1" '0x%016X'; return; fi
    printf -v "$1" '0x%016X' $(( $2 << shifts ))
}

eq() {
    printf -v "$1" '0x%016X' $(( $2 == $3 ))
}

lts() {
    printf -v "$1" '0x%016X' $(( $2 < $3))
}

