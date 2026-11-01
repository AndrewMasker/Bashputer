#!/usr/bin/env bash
# config.sh

declare -A CLOCKABLE
declare -A COMPONENTS

# Declare components that shoudl recieve clock pulses
CLOCKABLE[cpu]="$MY_DIR"/../Components/cpu/cpu.sh
CLOCKABLE[loader]="$MY_DIR"/../Components/loader/loader.sh

# Declare the clock
CLOCK="$MY_DIR"/../Components/clock/clock.sh

# Declare the bus interconnect
BUS_INTERCONNECT="$MY_DIR"/../Components/bus_interconnect/bus_interconnect.sh

# Declare the non clockable, memory ampped components here
COMPONENTS[keyboard]="$MY_DIR"/../Components/keyboard/keyboard.sh
COMPONENTS[ram]="$MY_DIR"/../Components/ram/ram.sh
COMPONENTS[rom]="$MY_DIR"/../Components/ram/ram.sh
COMPONENTS[screen]="$MY_DIR"/../Components/screen/screen.sh
COMPONENTS[timer]="$MY_DIR"/../Components/timer/timer.sh