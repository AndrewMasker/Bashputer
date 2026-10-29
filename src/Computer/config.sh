#!/usr/bin/env bash
# config.sh

declare -A COMPONENTS

COMPONENTS[cpu]="$MY_DIR"/../Components/cpu/cpu.sh
COMPONENTS[bus_interconnect]="$MY_DIR"/../Components/bus_interconnect/bus_interconnect.sh
COMPONENTS[keyboard]="$MY_DIR"/../Components/keyboard/keyboard.sh
COMPONENTS[ram]="$MY_DIR"/../Components/ram/ram.sh
COMPONENTS[rom]="$MY_DIR"/../Components/ram/ram.sh
COMPONENTS[screen]="$MY_DIR"/../Components/screen/screen.sh
COMPONENTS[clock]="$MY_DIR"/../Components/clock/clock.sh
COMPONENTS[timer]="$MY_DIR"/../Components/timer/timer.sh