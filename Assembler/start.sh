#!/usr/bin/env bash
# start.sh

help() {
    cat <<HELP
USAGE: assember.sh  [options] <source.bassm/basm/bsm>
    -o DIR , --output DIR       write the hex and intermediates here (default: <source>/hex)
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
        -h|--help) help; exit 0 ;;
        -k|--keep) KEEP=true ;;
        -o|--output) if (( $# >= 2 )); then OUT=$2; shift; else usage_Error "$1 needs a file name"; fi ;;
        -o=*|--output=*) OUT=${1#*=} ;;
        -*) usage_Error "unknown option '$1'" ;;
        *) if [[ -z $SRC ]]; then SRC=$1; else usage_Error "source already set to: '$SRC', cannot set source to '$1' as well"; fi
    esac
    shift
done
if [[ -z $SRC ]]; then
    usage_Error "no source file passed"
fi
name=${SRC##*/}
if [[ $name == ?*.* ]]; then
    base=${SRC%.*}
else
    usage_Error "invalid source file of '$SRC'"
fi
if [[ -n $OUT ]]; then
    if ! is_Valid_Dir "$OUT"; then
        usage_Error "can't use '$OUT' as an output directory"
    fi
else
    if ! is_Valid_Dir "$base"; then
        usage_Error "can't use '$base' as an output directory"
    fi
    OUT=$base
fi
if [[ ! -f $SRC || ! -r $SRC ]]; then
    usage_Error "cannot read source file '$SRC'"
fi
if $KEEP; then 
    WORK="$base"/work
    if ! is_Valid_Dir "$WORK"; then
        usage_Error "can't use '$WORK' as a work output directory"
    fi
else
    WORK=$(mktemp -d)
    on_Exit() { rm -rf "$WORK"; }
fi

mkdir -p "$WORK"
mkdir -p "$OUT"
