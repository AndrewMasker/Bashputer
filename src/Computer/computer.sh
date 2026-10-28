#!/usr/bin/env bash
# computer.sh

COMPONENT_NAME=COMPUTER

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/config.sh
source "$MY_DIR"/../config.sh
source "$MY_DIR"/../errors.sh
source "$MY_DIR"/../utils.sh
source "$MY_DIR"/utils.sh

FIFO_DIR=$(mktemp -d)
declare -A PID IN OUT

on_Exit() {
    local name
    for name in "${!PID[@]}"; do kill "${PID[$name]}" 2>/dev/null || true; done
    wait
    if [[ -n ${FIFO_DIR-} ]]; then rm -rf "$FIFO_DIR"; fi

    if [[ -n ${SAVED_STTY-} ]]; then
        printf '\e[0m\e[?25h' >/dev/tty
        stty "$SAVED_STTY" </dev/tty
    fi
}

if ! SAVED_STTY=$(stty -g 2>/dev/null </dev/tty); then
    die "no controlling terminal"
fi
stty -echo -icanon min 1 time 0 </dev/tty

for name in "${!COMPONENTS[@]}"; do
    start_Component "$name" "${COMPONENTS[$name]}"
done
for name in "${!COMPONENTS[@]}"; do
    connect_Component "$name"
done

run_Computer() {
    start_Component "rom" "$MY_DIR"/cartridges/snake.sh
    computer_Step
}

trap 'exit 130' INT
trap 'exit 143' TERM

rom_disc=$1
run_Computer $rom_disc



