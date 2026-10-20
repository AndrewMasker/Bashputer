#!/usr/bin/env bash
# alu.sh

add() {
    printf '0x%016X' $(( $1 + $2 ))
}