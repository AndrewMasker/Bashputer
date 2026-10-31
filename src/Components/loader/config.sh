#!/usr/bin/env bash
# config.sh

printf -v CART_ADDR '0x%016X' 0
printf -v COMMAND_ADDR '0x%016X' 1
printf -v BUSY_ADDR '0x%016X' 2
printf -v RESULT_ADDR '0x%016X' 3
printf -v START_ADDR '0x%016X' 4
printf -v END_ADDR '0x%016X' 12
printf -v OFFSET_ADDR '0x%016X' 20

UNMAPPED_DATA=0xFF