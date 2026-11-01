#!/usr/bin/env bash
# utils.sh

handle_Event() {
    local msg=$1
    case $msg in
        "cpu halted") RUNNING=false; ;;
        "cpu stalled") : ;;
        *) die "unhandled event of '$msg'"
    esac
}