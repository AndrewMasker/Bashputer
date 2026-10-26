#!/usr/bin/env bash
# utils.sh

get_Message() {
    local name=$1 varname=$2 exit_status=0
    read -r -t $TIMEOUT "$varname" <&"${OUT[$name]}" || exit_status=$?
    if (( exit_status > 128)); then die "component '$name' didn't repond within '$TIMEOUT' seconds"; fi
    if (( exit_status != 0)); then
        exit_status=0; wait "${PID[$name]}" || exit_status=$?
        unset 'PID[$name]'
        die "component '$name' crashed with exit status '$exit_status'"
    fi
}

send_Message() {
    local name=$1
    local message=$2
    printf '%s\n' "$message" >&"${IN[$name]}"
}

start_Component() {
    local name=$1 script=$2
    mkfifo "$FIFO_DIR/$name.in" "$FIFO_DIR/$name.out"
    bash "$script" < "$FIFO_DIR/$name.in" > "$FIFO_DIR/$name.out" &
    PID[$name]=$!
}

connect_Component() {
    local name=$1
    exec {IN[$name]}> "$FIFO_DIR/$name.in"
    exec {OUT[$name]}< "$FIFO_DIR/$name.out"
}

shutdown_All_Components() {
    local name exit_status
    for name in "${!PID[@]}"; do send_Message "$name" shutdown; done
    for name in "${!PID[@]}"; do 
        exit_status=0; wait "${PID[$name]}" || exit_status=$?
        if (( exit_status != 0 )); then
            die "component '$name' exited with status '$exit_status'"
        fi
        unset 'PID[$name]'
    done
}