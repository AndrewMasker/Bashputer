#!/usr/bin/env bash
# keyboard.sh

COMPONENT_NAME="Keyboard"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh
source "$MY_DIR"/config.sh

export LC_ALL=C

exec {TTY}<"/dev/tty"

KEY_BUF=()

poll_TTY() {
    local char byte
    while read -r -t 0 -u "$TTY"; do
        IFS= read -r -d '' -n 1 -u "$TTY" char || die "tty closed"
        printf -v 'byte' '0x%02X' "'$char"
        KEY_BUF+=("$byte")
    done
}

parse_Load() {
    local addr=$1
    if ! is_16_Digit_Hex "$addr"; then
        die "address '$addr' has wrong format. Must be '0x%016X'"
    fi
    poll_TTY
    case $addr in
        "$STATUS_ADDR")
            if (( ${#KEY_BUF[@]} )); then
                echo "data 0x01"
            else
                echo "data 0x00"
            fi
            ;;
        "$DATA_ADDR")
            if (( ${#KEY_BUF[@]} )); then
                echo "data ${KEY_BUF[0]}"
                KEY_BUF=("${KEY_BUF[@]:1}")
            else
                echo "data $NO_DATA"
            fi
            ;;
        "$CLEAR_ADDR")
            KEY_BUF=()
            echo "data $NO_DATA"
            ;;
        *)
            echo "data $UNMAPPED_DATA"
            ;;
    esac
}

parse_Input() {
    local type=$1 value=$2
    case $type in
        load) parse_Load "$value" ; echo done ;;
        *) die "unknown input type" ;;
    esac
}

run_KEYBOARD() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            shutdown) exit 0 ;;
            *) parse_Input "$type" "$value" ;;
        esac
    done
    die "input stream closed without shutdown"
}

run_KEYBOARD