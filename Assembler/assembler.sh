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
    
done