#!/usr/bin/env bash
# opcodes.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/errors.sh

help() {
    cat <<HELP
USAGE: assember.sh  [options] <source.bassm/basm/bsm>
    -o FILE , --output FILE     write the hex and intermediates here (default: <source>.hex)
    -k , --keep                 keep the intermediate files
    -h , --help                 show this help message
HELP
}

usage_Error() {
    printf 'assembler.sh: %s\n' "$*" >&2
    printf "Try 'assembler.sh --help'.\n" >&2
    _DYING=true
    exit 64
}

OUT=''
SRC=''
KEEP=false
while (( $# > 0 )); do
    case $1 in 
        -h|--help) help(); exit 0 ;;
        -k|--k) KEEP=true ;;
        -o|--output) if (( $# >= 2 )); then OUT=$2; shift; else usage_Error "$1 needs a file name"; fi ;;
        -o=*|--output=*) OUT=${1#*=} ;;
        -*) usage_Error "unknown option '$1'" ;;
        *) if [[ -z $SRC ]]; then SRC=$1; else usage_Error "source already set to: '$SRC', cannot set source to '$1' as well"
    esac
    shift
done
if [[ -n $SRC ]]; then
    usage_Error "no source file passed"
fi
name=${SRC##*/}
if [[ $name == ?*.*]]; 