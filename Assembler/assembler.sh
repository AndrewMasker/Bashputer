#!/usr/bin/env bash
# assembler.sh

COMPONENT_NAME=ASSEMBLER

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/errors.sh
source "$MY_DIR"/utils.sh

source "$MY_DIR"/start.sh


run_Stage() {
    local name=$1 status=0
    shift
    bash "$@" || status=$?
    case $status in
        0) return 0 ;;
        2) printf "assembler: error during the %s stage (errors in source)\n" "$name" >&2 ;;
        126|127) printf "assembler: error during the %s stage. Could not run '%s'. Is the source correct?\n" "$name" "$*" >&2; status=1 ;;
        *) printf "assembler: assmbler error with status '%s' during the %s stage\n" "$status" "$name" >&2 ;;
    esac
    _DYING=true
    exit "$status"
}

run_Stage preprocessor "$MY_DIR"/stages/preprocessor.sh "$SRC" > "$WORK"/pre.bassm
run_Stage processor "$MY_DIR"/stages/processor.sh "$WORK/pre.bassm" > "$WORK"/post.bassm
# run_Stage hexer "$MY_DIR"/stages/hexer.sh "$WORK/post.bassm" > "$OUT"/hex