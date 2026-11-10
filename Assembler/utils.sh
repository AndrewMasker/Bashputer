#!/usr/bin/env bash
# utils.sh

is_Valid_Dir() {
    local path=${1:-}
    if [[ -z $path ]]; then
        return 1
    fi
    if [[ -e $path ]]; then
        if [[ -d $path && -w $path ]]; then
            return 0
        else 
            return 1
        fi
    fi
    while [[ ! -e $path ]]; do
        if [[ $path != */* ]]; then
            path=.
            break
        fi
        path=${path%/*}
        if [[ -z $path ]]; then
            path=/
        fi
    done
    if [[ -d $path && -w $path ]]; then
        return 0
    else
        return 1
    fi
}
