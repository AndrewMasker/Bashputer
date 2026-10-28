#!/usr/bin/env bash
# clock.sh

COMPONENT_NAME="Clock"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/../../utils.sh
source "$MY_DIR"/config.sh

export {SLEEP_FD}<> <(:)

set_Now_Us() {
    printf -v "$1" '%d' "${EPOCHREALTIME/./}"
}

sleep_Us() {
    local us=$1 secs
    if ((us <= 0)); then
        return 0
    fi
    printf -v secs '%d.%06d' $(( us / 1000000 )) $(( us % 1000000))
    read -r -t "$secs" -u "$SLEEP_FD" || true
}

set_Now_Us LAST_PULSE

wait_For_Next_Pulse() {
    local now
    set_Now_Us now
    NEXT_PULSE=$(( LAST_PULSE +  PERIOD_US ))
    if (( NEXT_PULSE > now )); then
        sleep_Us $(( NEXT_PULSE - now ))
        LAST_PULSE=$NEXT_PULSE
    else
        LAST_PULSE=$now
    fi
}

run_CLOCK() {
    while read -r type value || [[ -n ${type-} ]]; do
        case $type in
            wait) wait_For_Next_Pulse ; echo clock ;;
            shutdown) exit 0 ;;
            *) die "Unknown input of '$type'" ;;
        esac
    done
    die "input stream closed without shutdown"
}

run_CLOCK