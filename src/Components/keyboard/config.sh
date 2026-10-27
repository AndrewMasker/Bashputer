#!/usr/bin/env bash
# config.sh

printf -v 'STATUS_ADDR' '0x%016X' 0
printf -v 'DATA_ADDR' '0x%016X' 1
printf -v 'CLEAR_ADDR' '0x%016X' 2
NO_DATA=0x00
UNMAPPED_DATA=0xFF