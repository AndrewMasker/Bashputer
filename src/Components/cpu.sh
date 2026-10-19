#!/usr/bin/env bash
# cpu.sh

declare -A state

parse_Input() {
    local type = $1
    local value = $2
    if [[ $type == "clock_pulse" ]]; then {
        return parse_Clock_Pulse
    }
    elif [[ $type == "instruction" ]]; then {
        return parse_Instruction $value
    }
    elif [[ $type == "data" ]]; then {
        return parse_Data $value
    }
}

while read -r type value; do
    parse_Input $type $value
done