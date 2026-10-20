#!/usr/bin/env bash
# cpu.sh

declare -A state

parse_Data() {
    local value=$1
}

parse_Input() {
    local type=$1
    local value=$2
    case $type in
    clock_pulse) parse_Clock_Pulse ;;
    data) parse_Data "$value" ;;
    *) echo "cpu: unknown input '$type'" >&2 ;; 
    esac
}

while read -r type value; do
    parse_Input "$type" "$value"
done