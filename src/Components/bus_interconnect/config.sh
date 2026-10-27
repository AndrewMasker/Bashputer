#!/usr/bin/env bash
# config.sh

NAMES=(       none          rom   screen          keyboard            ram              )
ADDR_LOW=(    $(( 1<<63 ))  0     $(( 64*1000 ))  $(( 3*64*1000 ))    $(( 4*64*1000 )) )
PERMISSIONS=( RW            R     RW              R                   RW               )
