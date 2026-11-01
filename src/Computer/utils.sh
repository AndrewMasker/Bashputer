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

handle_Clockable_Message() {
    local master=$1 msg=$2 type rest
    read -r type rest <<< "$msg"
    case $type in
        load|store) bus_Request "$master" "$msg" ;;
        "$master") handle_Event "$msg" ;;
        *) die "'$master' ent unknown command of '$msg'"
    esac

}

bus_Request() {
    local master=$1 msg=$2 reply first type rest name
    send_Message "$ROUTER" "$msg" # Tell the router the message
    get_Message "$ROUTER" reply # Get the router's message
    read -r first type rest <<< "$reply" # Break up the router's message into its component parts
    case $first in
        data) send_Message "$master" "$reply" ;; # This means the bus answered a load instead of forwarding, i.e. denied or unmapped
        done) : ;; # This means the bus answered a store instead of forwarding, i.e. no read permission
        *)
            # This means that the bus is forwarding to a component
            name=$first
            if [[ ! -v 'IN[$name]' ]]; then
                die "Component: '$master' routed to an unnamed component '$name'"
            fi
            send_Message "$name" "$type $rest" # Tell the component the message
            get_Message "$name" reply # Get the component's reply
            if [[ $type == load ]]; then # If the type was load we must forward the data back to the master
                send_Message "$master" "$reply" 
            else # else the type was store so we need to clean up the done that the ROUTER uses to indicate it is done
                get_Message "$ROUTER" reply
            fi
            ;;

    esac

}