#!/usr/bin/env bash
# computer.sh

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../errors.sh
source "$MY_DIR"/config.sh
source "$MY_DIR"/../utils.sh
source "$MY_DIR"/utils.sh

FIFO_DIR=$(mktemp -d)
declare -A PID IN OUT










