#!/usr/bin/env bash
# errors.sh

_DYING=false

die() {
    trap - ERR
    _DYING=true
    local i
    {
        printf '\n%s: FATAL: %s\n' "${COMPONENT_NAME:-component}" "$*"
        printf '    call stack (innermost first):\n'
        for (( i = 1; i < ${#FUNCNAME[@]}; i++ )); do
            [[ ${FUNCNAME[i]} == _on_Err || ${FUNCNAME[i]} == bad_State ]] && continue
            printf '    %-20s %s:%s\n' "${FUNCNAME[i]}" "${BASH_SOURCE[i]##*/}" "${BASH_LINENO[i-1]}"
        done
        if declare -F dump_State >/dev/null; then dump_State; fi
    } >&2
    exit 1
}

bad_State() {
    local pidx=$1
    die "${FUNCNAME[1]}: unexpected PROC_STATE '${PROC_STATE[pidx]-}' at depth $pidx"
}

_on_Err() {
    local status=$1 cmd=$2
    die "Command failed (status $status): $cmd"; fi
}

_on_Exit() {
    local status=$1
    if (( status != 0 )) && ! $_DYING; then 
    {
        printf '\n%s: FATAL: exited with status %s (bash errors above)\n' "${COMPONENT_NAME:-component}" "$status"
        if declare -F dump_State >/dev/null; then dump_State; fi
    } >&2
    fi
    if declare -F on_Exit >/dev/null; then on_Exit "$status"; fi
}

set -Eu
trap '_on_Err $? "$BASH_COMMAND"' ERR
trap '_on_Exit $?' EXIT