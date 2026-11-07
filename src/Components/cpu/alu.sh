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

inc() {
    local -n _target="$1"
    printf -v _target '0x%016X' $(( _target + 1 ))
}

inc() {
    local -n _target="$1"
    printf -v _target '0x%016X' $(( _target - 1 ))
}

neg() {
    printf -v "$1" '0x%016X' $(( -$2 ))
}

mul() {
    printf -v "$1" '0x%016X' $(( $2 * $3 ))
}

div() {
    printf -v "$1" '0x%016X' $(( $2 / $3 ))
}

rem() {
    printf -v "$1" '0x%016X' $(( $2 % $3 ))
}

lsr() {
    if (( $3 == 0)); then printf -v "$1" '0x%016X' $(( $2 )); return; fi
    if (( $3 >= 64 || $3 < 0 )); then printf -v "$1" '0x%016X' 0; return; fi
    local _asr=$(( $2 >> $3 ))
    local _mask=$(( ~( -1 <<  (64 - $3) ) ))
    printf -v "$1" '0x%016X' $(( _asr &  _mask))
}

asr() {
    local _shifts=$3
    if (( _shifts >= 64 || _shifts < 0 )); then _shifts=63; fi
    printf -v "$1" '0x%016X' $(( $2 >> _shifts ))
}

shl() {
    local _shifts=$3
    if (( _shifts >= 64 || _shifts < 0 )); then printf -v "$1" '0x%016X' 0; return; fi
    printf -v "$1" '0x%016X' $(( $2 << _shifts ))
}

eq() {
    printf -v "$1" '0x%016X' $(( $2 == $3 ))
}

neq() {
    printf -v "$1" '0x%016X' $(( $2 != $3 ))
}

lts() {
    printf -v "$1" '0x%016X' $(( $2 < $3))
}

lt() {
    local mask=$(( 1 << 63 ))
    printf -v "$1" '0x%016X' $(( ( $2 ^ mask ) < ( $3 ^ mask ) ))
}

les() {
    printf -v "$1" '0x%016X' $(( $2 <= $3))
}

le() {
    local mask=$(( 1 << 63 ))
    printf -v "$1" '0x%016X' $(( ( $2 ^ mask ) <= ( $3 ^ mask ) ))
}

