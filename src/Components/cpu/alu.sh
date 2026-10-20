#!/usr/bin/env bash
# alu.sh

add() {
    printf '%0x016X' $(( $1 + $2 ))
}