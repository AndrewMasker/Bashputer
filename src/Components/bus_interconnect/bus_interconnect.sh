#!/usr/bin/env bash
# bus_interconnect.sh

COMPONENT_NAME="Bus Interconnect"

MY_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$MY_DIR"/../../errors.sh
source "$MY_DIR"/config.sh