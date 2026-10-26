#!/usr/bin/env bash
# config.sh

declare -A COMPONENTS

COMPONENTS[cpu]="$MY_DIR"/../Components/cpu/cpu.sh
COMPONENTS[bus_interconnect]="$MY_DIR"/../Components/bus_interconnect/bus_interconnect.sh